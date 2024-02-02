
import 'dart:io';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:f_logs/model/flog/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class SystemLogDialog extends StatefulWidget {
  const SystemLogDialog({Key? key}) : super(key: key);

  @override
  State<SystemLogDialog> createState() => _SystemLogDialogState();
}

class _SystemLogDialogState extends State<SystemLogDialog> {
  bool isButtonDisabled = false;
  List<Log> logs = [];
  String logText = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllLogs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 5),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.translate('system_log')),
                Visibility(
                  visible: logs.length >= 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 10,
                    height: MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('clear_all'),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (await confirm(
                        context,
                          title: Text("${AppLocalizations.of(context)!.translate('confirm_remove_all_system_log')}"),
                          content: Text('${AppLocalizations.of(context)!.translate('confirm_remove_all_system_log_desc')}'),
                          textOK: Text('${AppLocalizations.of(context)!.translate('yes')}'),
                          textCancel: Text('${AppLocalizations.of(context)!.translate('no')}'),
                        )) {
                          FLog.clearLogs();
                          logs.clear();
                        }
                        //Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
            content: Card(
              elevation: 0,
              child: Container(
                height: MediaQuery.of(context).size.height / 1.5,
                width: MediaQuery.of(context).size.width / 1.2, // Adjust the width as needed
                child: logs.isNotEmpty ?
                ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: false,
                  itemCount: logs.length,
                  itemBuilder: (BuildContext context, int index) {
                    bool isErrorLog = logs[index].logLevel.toString() == "LogLevel.ERROR" ? true : false;
                    Color? tileColor = isErrorLog ? Colors.red[50] : Colors.blue[50];
                    Color fontColor = isErrorLog ? Colors.red : Colors.blue;
                    IconData iconData = isErrorLog ? Icons.warning : Icons.info;

                    return ListTile(
                      tileColor: tileColor,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                      title: Text(
                        isErrorLog ?
                        "${getFormattedTimeStamp(logs[index].timestamp.toString())}: ${logs[index].className}(${logs[index].methodName}) - ${logs[index].text}"
                        : "${getFormattedTimeStamp(logs[index].timestamp.toString())}: ${logs[index].text}",
                        style: TextStyle(
                          color: fontColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        iconData,
                        color: fontColor,
                      ),
                      onTap: () {
                        setState(() {
                          logs[index].isTapped = !logs[index].isTapped;
                        });
                      },
                      subtitle: logs[index].isTapped
                          ? Text(logs[index].exception == "null" ? "No description" : "${logs[index].exception}")
                          : null,
                    );
                  },
                ) :
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history),
                    Text("${AppLocalizations.of(context)!.translate('system_log_empty_desc')}"),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 12,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.backgroundColor,
                  ),
                  child: Text(AppLocalizations.of(context)!.translate('export')),
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    Directory appDocDir = await getApplicationDocumentsDirectory();
                    String sourceFilePath = appDocDir.path + '/flog.db';
                    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                    try {
                      File file = await File(sourceFilePath);
                      if (!await FlutterFileDialog.isPickDirectorySupported()) {
                        Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('file_export_not_supported'));
                        return;
                      } else {
                        final pickedDirectory = await FlutterFileDialog.pickDirectory();

                        if (pickedDirectory != null) {
                          final filePath = await FlutterFileDialog.saveFileToDirectory(
                            directory: pickedDirectory!,
                            data: file.readAsBytesSync(),
                            mimeType: "application/octet-stream",
                            fileName: "optimy_log_$timestamp.db",
                            replace: true,
                          );

                          if (filePath != null) {
                            Fluttertoast.showToast(msg: '${AppLocalizations.of(context)!.translate('file_export_success')}');
                          } else {
                            Fluttertoast.showToast(backgroundColor: Colors.red, msg: '${AppLocalizations.of(context)!.translate('file_export_cancel')}');
                          }
                        } else {
                          Fluttertoast.showToast(backgroundColor: Colors.red, msg: '${AppLocalizations.of(context)!.translate('file_export_cancel')}');
                        }
                      }
                      setState(() {
                        isButtonDisabled = false;
                      });
                    } catch (e) {
                      Fluttertoast.showToast(backgroundColor: Colors.red, msg: '${AppLocalizations.of(context)!.translate('file_export_error')}');
                      FLog.error(
                        className: "system_log_dialog",
                        text: "system log export error",
                        exception: e,
                      );
                      setState(() {
                        isButtonDisabled = false;
                      });
                    }
                  },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 12,
                child: ElevatedButton(
                  child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                          setState(() {
                            isButtonDisabled = true;
                          });
                          closeDialog(context);
                        },
                ),
              ),
            ],
          );
        } else {
          ///mobile layout
          return AlertDialog(
            titlePadding: EdgeInsets.fromLTRB(24, 12, 24, 0),
            contentPadding: EdgeInsets.fromLTRB(18, 10, 18, 0),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.translate('system_log')),
                Visibility(
                  visible: logs.length >= 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 8,
                    height: MediaQuery.of(context).size.height / 12,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('clear_all'),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (await confirm(
                          context,
                          title: Text("${AppLocalizations.of(context)!.translate('confirm_remove_all_system_log')}"),
                          content: Text('${AppLocalizations.of(context)!.translate('confirm_remove_all_system_log_desc')}'),
                          textOK: Text('${AppLocalizations.of(context)!.translate('yes')}'),
                          textCancel: Text('${AppLocalizations.of(context)!.translate('no')}'),
                        )) {
                          FLog.clearLogs();
                          setState(() {});
                        }
                        //Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
            content: Card(
              elevation: 0,
              child: Container(
                height: MediaQuery.of(context).size.height / 2,
                width: 500, // Adjust the width as needed
                child: logs.isNotEmpty ?
                ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: false,
                  itemCount: logs.length,
                  itemBuilder: (BuildContext context, int index) {
                    bool isErrorLog = logs[index].logLevel.toString() == "LogLevel.ERROR" ? true : false;
                    Color? tileColor = isErrorLog ? Colors.red[50] : Colors.blue[50];
                    Color fontColor = isErrorLog ? Colors.red : Colors.blue;
                    IconData iconData = isErrorLog ? Icons.warning : Icons.info;

                    return ListTile(
                      tileColor: tileColor,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                      title: Text(
                        isErrorLog ?
                        "${getFormattedTimeStamp(logs[index].timestamp.toString())}: ${logs[index].className}(${logs[index].methodName}) - ${logs[index].exception}"
                            : "${getFormattedTimeStamp(logs[index].timestamp.toString())}: ${logs[index].text}",
                        style: TextStyle(
                          color: fontColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ) :
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history),
                    Text("${AppLocalizations.of(context)!.translate('system_log_empty_desc')}"),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                  child: Text(AppLocalizations.of(context)!.translate('export')),
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                          setState(() {
                            isButtonDisabled = true;
                          });
                          Directory appDocDir = await getApplicationDocumentsDirectory();
                          String sourceFilePath = appDocDir.path + '/flog.db';
                          String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                          try {
                            File file = await File(sourceFilePath);
                            if (!await FlutterFileDialog.isPickDirectorySupported()) {
                              Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('file_export_not_supported'));
                              return;
                            } else {
                              final pickedDirectory = await FlutterFileDialog.pickDirectory();

                              if (pickedDirectory != null) {
                                final filePath = await FlutterFileDialog.saveFileToDirectory(
                                  directory: pickedDirectory!,
                                  data: file.readAsBytesSync(),
                                  mimeType: "application/octet-stream",
                                  fileName: "optimy_log_$timestamp.db",
                                  replace: true,
                                );

                                if (filePath != null) {
                                  Fluttertoast.showToast(msg: '${AppLocalizations.of(context)!.translate('file_export_success')}');
                                } else {
                                  Fluttertoast.showToast(backgroundColor: Colors.red, msg: '${AppLocalizations.of(context)!.translate('file_export_cancel')}');
                                }
                              } else {
                                Fluttertoast.showToast(backgroundColor: Colors.red, msg: '${AppLocalizations.of(context)!.translate('file_export_cancel')}');
                              }
                            }
                            setState(() {
                              isButtonDisabled = false;
                            });
                          } catch (e) {
                            Fluttertoast.showToast(backgroundColor: Colors.red, msg: '${AppLocalizations.of(context)!.translate('file_export_error')}');
                            FLog.error(
                              className: "system_log_dialog",
                              text: "system log export error",
                              exception: e,
                            );
                            setState(() {
                              isButtonDisabled = false;
                            });
                          }
                        },
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.height / 10,
                child: ElevatedButton(
                  child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: isButtonDisabled
                      ? null
                      : () {
                          // Disable the button after it has been pressed
                          setState(() {
                            isButtonDisabled = true;
                          });
                          closeDialog(context);
                        },
                ),
              ),
            ],
          );
        }
      });
    });
  }

  getAllLogs() async {
    logs = await FLog.getAllLogs();
    setState(() {
      for(int i = 0; i < logs.length; i++){
        logText += '${logs[i].timestamp}: ${logs[i].className}(${logs[i].text}) - ${logs[i].exception}\n';
      }
    });
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  getFormattedTimeStamp(String timeStamp) {
    DateTime dateTime = DateFormat("dd MMMM yyyy hh:mm:ss a").parse(timeStamp);
    String formattedTimestamp = DateFormat("dd/MM/yyyy HH:mm:ss").format(dateTime);
    return formattedTimestamp;
  }
}
