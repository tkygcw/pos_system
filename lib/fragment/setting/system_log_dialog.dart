import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:f_logs/model/flog/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final adminPosPinController = TextEditingController();
  bool _submitted = false;
  bool inProgress = false;

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
        return AlertDialog(
          titlePadding: constraints.maxWidth > 900 && constraints.maxHeight > 500 ? EdgeInsets.fromLTRB(24, 24, 24, 0) : EdgeInsets.fromLTRB(24, 12, 24, 0),
          contentPadding: constraints.maxWidth > 900 && constraints.maxHeight > 500 ? EdgeInsets.fromLTRB(24, 16, 24, 5) : EdgeInsets.fromLTRB(18, 10, 18, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.translate('system_log')),
              Visibility(
                visible: logs.length >= 1,
                child: SizedBox(
                  width: constraints.maxWidth > 900 && constraints.maxHeight > 500
                      ? MediaQuery.of(context).size.width / 10
                      : MediaQuery.of(context).orientation == Orientation.landscape
                      ? MediaQuery.of(context).size.width / 6
                      : MediaQuery.of(context).size.width / 4,
                  height: constraints.maxWidth > 900 && constraints.maxHeight > 500
                      ? MediaQuery.of(context).size.height / 20
                      : MediaQuery.of(context).orientation == Orientation.landscape
                      ? MediaQuery.of(context).size.height / 12
                      : MediaQuery.of(context).size.height / 26,
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
                    },
                  ),
                ),
              ),
            ],
          ),
          content: Card(
            elevation: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / (constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 1.5 : 2),
              width: constraints.maxWidth > 900 && constraints.maxHeight > 500 ? MediaQuery.of(context).size.width / 1.2 : 500,
              child: logs.isNotEmpty ?
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: false,
                itemCount: logs.length,
                itemBuilder: (BuildContext context, int index) {
                  final reversedIndex = logs.length - 1 - index;
                  bool isErrorLog = logs[reversedIndex].logLevel.toString() == "LogLevel.ERROR" ? true : false;
                  Color? tileColor = isErrorLog ? Colors.red[50] : Colors.blue[50];
                  Color fontColor = isErrorLog ? Colors.red : Colors.blue;
                  IconData iconData = isErrorLog ? Icons.warning : Icons.info;

                  return ListTile(
                    tileColor: tileColor,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                    title: Text(
                      isErrorLog ?
                      "${getFormattedTimeStamp(logs[reversedIndex].timestamp.toString())}: ${logs[reversedIndex].className}(${logs[reversedIndex].methodName}) - ${logs[reversedIndex].text}"
                          : "${getFormattedTimeStamp(logs[reversedIndex].timestamp.toString())}: ${logs[reversedIndex].text}",
                      style: TextStyle(
                        color: fontColor,
                        fontSize: constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 16.0 : 12.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    leading: constraints.maxWidth > 900 && constraints.maxHeight > 500 || MediaQuery.of(context).orientation == Orientation.landscape ? Icon(
                      iconData,
                      color: fontColor,
                    ) : null,
                    onTap: () {
                      setState(() {
                        logs[reversedIndex].isTapped = !logs[reversedIndex].isTapped;
                      });
                    },
                    subtitle: logs[reversedIndex].isTapped
                        ? Text(logs[reversedIndex].exception == "null" ? "No description" : "${logs[reversedIndex].exception}",
                        style: constraints.maxWidth > 900 && constraints.maxHeight > 500 ? TextStyle(fontSize: 14.0): TextStyle(fontSize: 12.0))
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
            constraints.maxWidth > 900 && constraints.maxHeight > 500 ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                  height: MediaQuery.of(context).size.height / (constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 12 : 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
                SizedBox(width: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                  height: MediaQuery.of(context).size.height / (constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 12 : 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                    child: Text(AppLocalizations.of(context)!.translate('export')),
                    onPressed: isButtonDisabled
                        ? null
                        : () async {

                      setState(() {
                        isButtonDisabled = true;
                      });
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, StateSetter setState) {
                            return Container(
                              child: AlertDialog(
                                title: Text(AppLocalizations.of(context)!.translate('choose_an_option')),
                                content: !inProgress ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width / 4,
                                      height: MediaQuery.of(context).size.height / (constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 12 : 10),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          setState(() {
                                            inProgress = true;
                                          });
                                          await dataZip(1);
                                          if(mounted){
                                            setState(() {
                                              inProgress = false;
                                            });
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: Text(AppLocalizations.of(context)!.translate('db_export')),
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width / 4,
                                      height: MediaQuery.of(context).size.height / (constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 12 : 10),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          setState(() {
                                            inProgress = true;
                                          });
                                          await dataZip(2);
                                          if(mounted){
                                            setState(() {
                                              inProgress = false;
                                            });
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: Text(AppLocalizations.of(context)!.translate('db_sync')),
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width / 4,
                                      height: MediaQuery.of(context).size.height / (constraints.maxWidth > 900 && constraints.maxHeight > 500 ? 12 : 10),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          // await showSecondDialog(context, color);
                                          setState(() {
                                            inProgress = true;
                                          });
                                          await dataZip(3);
                                          FLog.clearLogs();
                                          logs.clear();
                                          if(mounted){
                                            setState(() {
                                              inProgress = false;
                                            });
                                          }
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(AppLocalizations.of(context)!.translate('debug')),
                                      ),
                                    ),
                                  ],
                                )
                                    : Container(
                                    height: 200,
                                    child: CustomProgressBar()),
                              ),
                            );
                          });
                        },
                      );
                      setState(() {
                        isButtonDisabled = false;
                      });
                    },
                  ),
                ),
              ],
            ) :
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 2.5 : MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).orientation == Orientation.landscape ? MediaQuery.of(context).size.height / 10 : MediaQuery.of(context).size.height / 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                      child: Text(AppLocalizations.of(context)!.translate('export')),
                      onPressed: isButtonDisabled
                          ? null
                          : () async {

                        setState(() {
                          isButtonDisabled = true;
                        });
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(builder: (context, StateSetter setState) {
                              return Container(
                                child: AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.translate('choose_an_option')),
                                  content: !inProgress ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        height: MediaQuery.of(context).size.height / 16,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              inProgress = true;
                                            });
                                            await dataZip(1);
                                            if(mounted){
                                              setState(() {
                                                inProgress = false;
                                              });
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text(AppLocalizations.of(context)!.translate('db_export')),
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      SizedBox(
                                        width: 300,
                                        height: MediaQuery.of(context).size.height / 16,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              inProgress = true;
                                            });
                                            await dataZip(2);
                                            if(mounted){
                                              setState(() {
                                                inProgress = false;
                                              });
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text(AppLocalizations.of(context)!.translate('db_sync')),
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      SizedBox(
                                        width: 300,
                                        height: MediaQuery.of(context).size.height / 16,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            // await showSecondDialog(context, color);
                                            setState(() {
                                              inProgress = true;
                                            });
                                            await dataZip(3);
                                            if(mounted){
                                              setState(() {
                                                inProgress = false;
                                              });
                                            }
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(AppLocalizations.of(context)!.translate('debug')),
                                        ),
                                      ),
                                    ],
                                  )
                                      : Container(
                                      height: 200,
                                      child: CustomProgressBar()),
                                ),
                              );
                            });
                          },
                        );
                        setState(() {
                          isButtonDisabled = false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      });
    });
  }

  Future<void> addDirectoryToZip(ZipFileEncoder encoder, Directory dir, List<String> excludeDirs) async {
    var entities = dir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        bool shouldExclude = excludeDirs.any((excludeDir) => entity.path.contains('/$excludeDir/'));
        if (!shouldExclude) {
          String relativePath = entity.path.replaceFirst(dir.path, '');
          String zipPath = 'optimy.com.my$relativePath';
          encoder.addFile(entity, zipPath);
        }
      }
    }
  }

  dataZip(int exportType) async {
    setState(() {
      inProgress = true;
    });
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    Directory tempDir = await getTemporaryDirectory();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String zipFilePath = '${tempDir.path}/optimy_data_export_$timestamp.zip';

    String sourceFlogPath = appDocDir.path + '/flog.db';
    String sourceDBPath = appDocDir.parent.path + '/databases/pos.db';

    var encoder = ZipFileEncoder();
    encoder.create(zipFilePath);
    if(exportType == 3) {
      await addDirectoryToZip(encoder, appDocDir.parent, ['flutter_assets', 'cache', 'lib']);
    } else {
      encoder.addFile(File(sourceFlogPath));
      encoder.addFile(File(sourceDBPath));
    }
    encoder.close();

    if(exportType == 1) {
      await dataExport(zipFilePath, timestamp);
    } else if(exportType == 2){
      await dataSync(zipFilePath, timestamp, 0);
    } else {
      await dataSync(zipFilePath, timestamp, 1);
    }
  }

  dataExport(String zipFilePath, String timestamp) async {
    try {
      if (!await FlutterFileDialog.isPickDirectorySupported()) {
        Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('file_export_not_supported'));
        return;
      } else {
        final pickedDirectory = await FlutterFileDialog.pickDirectory();

        if (pickedDirectory != null) {
          final filePath = await FlutterFileDialog.saveFileToDirectory(
            directory: pickedDirectory!,
            data: File(zipFilePath).readAsBytesSync(),
            mimeType: "application/zip",
            fileName: "optimy_data_$timestamp.zip",
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
        text: "data export error",
        exception: e,
      );
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  dataSync(String zipFilePath, String timestamp, int isDebug) async {
    try {
      String fileName;
      if(isDebug == 1) {
        fileName = "optimy_debug_$timestamp.zip";
      } else {
        fileName = "optimy_data_$timestamp.zip";
      }

      int fileSize = (File(zipFilePath).lengthSync() / 1024).toInt();
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');

      var request = http.MultipartRequest('POST', Domain.local_data_export)
        ..fields['local_data_export'] = '1'
        ..fields['debug'] = isDebug.toString()
        ..fields['branch_id'] = branch_id.toString()
        ..fields['file_name'] = fileName
        ..fields['file_size'] = fileSize.toString()
        ..files.add(await http.MultipartFile.fromPath('zipFile', zipFilePath, filename: fileName));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        if(jsonResponse['status'] == '1') {
          setState(() {
            inProgress = false;
          });
          Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('file_export_success'));
          FLog.info(
            className: "system_log_dialog",
            text: "File uploaded successfully",
          );
        } else {
          Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('file_export_error'));
          FLog.error(
            className: "system_log_dialog",
            text: "Database upload failed",
            exception: "server return failed",
          );
        }
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('file_export_error'));
        FLog.error(
          className: "system_log_dialog",
          text: "Database upload failed",
          exception: "server return failed",
        );
      }

      setState(() {
        isButtonDisabled = false;
      });
    } catch (e) {
      Fluttertoast.showToast(backgroundColor: Colors.red, msg: AppLocalizations.of(context)!.translate('file_export_error'));
      FLog.error(
        className: "system_log_dialog",
        text: "Database upload failed",
        exception: e,
      );
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Center(
              child: SingleChildScrollView(
                child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('enter_debug_pin')),
                  content: !inProgress ? SizedBox(
                    height: 75.0,
                    width: 350.0,
                    child: ValueListenableBuilder(
                        valueListenable: adminPosPinController,
                        builder: (context, TextEditingValue value, __) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              autofocus: true,
                              onSubmitted: (input) {
                                setState(() {
                                  isButtonDisabled = true;
                                });
                                _submit(context);
                                if(mounted){
                                  setState(() {
                                    isButtonDisabled = false;
                                    inProgress = false;
                                  });
                                }
                              },
                              obscureText: true,
                              controller: adminPosPinController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                errorText: _submitted
                                    ? errorPassword == null
                                    ? errorPassword
                                    : AppLocalizations.of(context)?.translate(errorPassword!)
                                    : null,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: color.backgroundColor),
                                ),
                                labelText: "PIN",
                              ),
                            ),
                          );
                        }),
                  )
                  : Container(
                      height: 100,
                      child: CustomProgressBar()
                    ),
                  actions: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.backgroundColor,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('yes'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                          setState(() {
                            isButtonDisabled = true;
                          });
                          Navigator.of(context).pop();
                          if(mounted){
                            setState(() {
                              isButtonDisabled = false;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.buttonColor,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('yes'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () async {
                          setState(() {
                            isButtonDisabled = true;
                          });
                          _submit(context);
                          if(mounted){
                            setState(() {
                              isButtonDisabled = false;
                              inProgress = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  void _submit(BuildContext context) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      await readAdminData(adminPosPinController.text);
    } else {
      setState(() {
        isButtonDisabled = false;
        inProgress = false;
      });
    }
  }

  readAdminData(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? branch_id = prefs.getInt('branch_id').toString();

      if(branch_id != null){
        if(pin == branch_id.padLeft(6, '0')) {

          print("pin status: correct");
          await dataZip(3);
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('wrong_pin_please_insert_valid_pin')}");
        }
      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('something_went_wrong_please_try_again_later')}");
      }

    } catch (e) {
      print('delete error ${e}');
    }
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