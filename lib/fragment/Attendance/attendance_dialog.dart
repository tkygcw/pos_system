import 'dart:async';
import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/attendance.dart';
import 'package:pos_system/object/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class AttendanceDialog extends StatefulWidget {
  const AttendanceDialog({Key? key}) : super(key: key);

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  bool isButtonDisabled = false;
  List<User> users = [];
  String logText = "";
  bool _submitted = false;
  final adminPosPinController = TextEditingController();
  bool isLogOut = false;
  late bool clockedIn = false;
  late DateTime currentTime;
  late Timer timer;
  bool _obscureText = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllUsers();
    currentTime = DateTime.now();
    // Start the timer to update currentTime every second
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(
      builder: (context, ThemeColor color, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
              return AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 5),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.translate('clock_in_out')),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy - hh:mm:ss a').format(currentTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Card(
                  elevation: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height / 2.5,
                    width: MediaQuery.of(context).size.width / 2.5,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: false,
                              itemCount: users.length,
                              itemBuilder: (BuildContext context, int index) {
                                bool isClockin = users[index].clock_in_at != null && users[index].clock_in_at != '' ? true : false;
                                Color? tileColor = isClockin ? Colors.blue[50] : Colors.red[50];
                                Color fontColor = isClockin ? Colors.blue : Colors.red;
                                IconData iconData = Icons.account_circle;
                  
                                return ListTile(
                                  tileColor: tileColor,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                                  title: Text(
                                    "${users[index].name}",
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
                                  trailing: Text(isClockin ? getDuration(users[index].clock_in_at!) : ''),
                                  onTap: () async {
                                    if(users[index].clock_in_at == null) {
                                      setState(() {
                                        users[index].clock_in_at = '';
                                      });
                                    }
                                    await showSecondDialog(context, color, users[index].user_id!, users[index].clock_in_at!);
                                  },
                                );
                              },
                            )
                        ),
                      ],
                    ),
                  ),
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
                        AppLocalizations.of(context)!.translate('close'),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                        setState(() {
                          adminPosPinController.clear();
                          isButtonDisabled = true;
                        });
                        Navigator.of(context).pop();
                        setState(() {
                          isButtonDisabled = false;
                        });
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
                    Text(AppLocalizations.of(context)!.translate('clock_in_out')),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy - hh:mm:ss a').format(currentTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Card(
                  elevation: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width / 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: false,
                              itemCount: users.length,
                              itemBuilder: (BuildContext context, int index) {
                                bool isClockin = users[index].clock_in_at != null && users[index].clock_in_at != '' ? true : false;
                                Color? tileColor = isClockin ? Colors.blue[50] : Colors.red[50];
                                Color fontColor = isClockin ? Colors.blue : Colors.red;
                                IconData iconData = Icons.account_circle;

                                return ListTile(
                                  tileColor: tileColor,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                                  title: Text(
                                    "${users[index].name}",
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
                                  trailing: Text(isClockin ? getDuration(users[index].clock_in_at!) : ''),
                                  onTap: () async {
                                    if(users[index].clock_in_at == null) {
                                      setState(() {
                                        users[index].clock_in_at = '';
                                      });
                                    }
                                    await showSecondDialog(context, color, users[index].user_id!, users[index].clock_in_at!);
                                  },
                                );
                              },
                            )
                        ),
                      ],
                    ),
                  ),
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
                        AppLocalizations.of(context)!.translate('close'),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                        setState(() {
                          adminPosPinController.clear();
                          isButtonDisabled = true;
                        });
                        Navigator.of(context).pop();
                        setState(() {
                          isButtonDisabled = false;
                        });
                      },
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  String? get errorPassword {
    final text = adminPosPinController.value.text;
    //readAdminData(text);
    if (text.isEmpty) {
      return 'password_required';
    }
    return null;
  }

  Future showSecondDialog(BuildContext context, ThemeColor color, int user_id, String clockInTime) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Center(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!
                      .translate('enter_your_pin')),
                  content: SizedBox(
                    height: 100.0,
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
                                });
                                _submit(context, user_id, clockInTime);
                              },
                              obscureText: _obscureText,
                              controller: adminPosPinController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                errorText: _submitted
                                    ? errorPassword == null
                                    ? errorPassword
                                    : AppLocalizations.of(context)
                                    ?.translate(errorPassword!)
                                    : null,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: color.backgroundColor),
                                ),
                                labelText: "PIN",
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    _obscureText = !_obscureText;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
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
                          AppLocalizations.of(context)!.translate('close'),
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                          setState(() {
                            adminPosPinController.clear();
                            isButtonDisabled = true;
                          });
                          Navigator.of(context).pop();
                          setState(() {
                            isButtonDisabled = false;
                          });
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
                          // setState(() {
                          //   isButtonDisabled = true;
                          //   willPop = false;
                          // });
                          _submit(context, user_id, clockInTime);
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

  void _submit(BuildContext context, int user_id, String clockInTime) async {
    setState(() => _submitted = true);
    if (errorPassword == null) {
      setState(() {
        isButtonDisabled = true;
      });
      await readAdminData(adminPosPinController.text, user_id, clockInTime);
      setState(() {
        isButtonDisabled = false;
        getAllUsers();
        adminPosPinController.clear();
      });
      return;
    } else {
      setState(() {
        isButtonDisabled = false;
      });
    }
  }

  readAdminData(String pin, int user_id, String clockInTime) async {
    List<String> _posTableValue = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pos_user = prefs.getString('pos_pin_user');
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final int? branch_id = prefs.getInt('branch_id');

      User? userData = await PosDatabase.instance.readSpecificUserWithPin(pin);
      if (userData != null) {
        if (userData.user_id == user_id) {
          if(clockInTime == '') {
            setState(() {
              clockedIn = false;
            });
          }
          else {
            setState(() {
              clockedIn = true;
            });
          }

          if(!clockedIn) {
            Attendance attendance = Attendance(
                attendance_key: '',
                branch_id: branch_id.toString(),
                user_id: user_id.toString(),
                role: userData.role,
                clock_in_at: dateTime,
                clock_out_at: '',
                duration: 0,
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''
            );
            Attendance data = await PosDatabase.instance.insertSqliteAttendance(attendance);

            Attendance? returnData = await insertAttendanceKey(data, dateTime);
            Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: "${AppLocalizations.of(context)?.translate('clocked_in_successful')}");
          } else {
            try {
              Attendance? data = await PosDatabase.instance.readAttendance(user_id);
              Duration duration = DateTime.now().difference(dateFormat.parse(clockInTime));
              int durationWork = duration.inMinutes;
              Attendance attendance = Attendance(
                  clock_out_at: dateTime,
                  duration: durationWork,
                  sync_status: data!.sync_status == 0 ? 0 : 2,
                  updated_at: dateTime,
                  user_id: user_id.toString()
              );
              int status = await PosDatabase.instance.updateAttendance(attendance);
              Fluttertoast.showToast(backgroundColor: Color(0xFF24EF10), msg: "${AppLocalizations.of(context)?.translate('clocked_out_successful')}");
            } catch(e){
              Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "Clock out: Something went wrong");
              FLog.error(
                className: "attendance_dialog",
                text: "attendance clock out failed",
                exception: "$e",
              );
            }
          }
          if (this.isLogOut == false) {
            Navigator.of(context).pop();
            // Navigator.of(context).pop();
          }
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('pin_not_match')}");
        }

      } else {
        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: "${AppLocalizations.of(context)?.translate('user_not_found')}");
        adminPosPinController.clear();
      }
    } catch(e) {
      print('failed to insert attendance error ${e}');
      FLog.error(
        className: "attendance_dialog",
        text: "attendance clock in insert failed",
        exception: "$e",
      );
    }
  }

  insertAttendanceKey(Attendance attendance, String dateTime) async {
    Attendance? returnData;
    String key = await generateAttendanceKey(attendance);
    Attendance data = Attendance(
        updated_at: dateTime,
        sync_status: 0,
        attendance_key: key,
        attendance_sqlite_id: attendance.attendance_sqlite_id
    );
    int status =  await PosDatabase.instance.updateAttendanceUniqueKey(data);
    // if(status == 1){
    //   Attendance? checkData = await PosDatabase.instance.readSpecificKitchenListByKey(data.kitchen_list_key!);
    //   if(checkData != null){
    //     returnData = checkData;
    //   }
    // }
    return returnData;
  }

  generateAttendanceKey(Attendance attendance) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var bytes = attendance.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + attendance.attendance_sqlite_id.toString() + branch_id.toString();
    return md5.convert(utf8.encode(bytes)).toString();
  }

  getAllUsers() async {
    users = await PosDatabase.instance.readAllUser();
    for(int i =0; i < users.length; i++) {
      var data = await PosDatabase.instance.readAttendance(users[i].user_id!);
      if(data != null) {
        users[i].clock_in_at = data!.clock_in_at;
        users[i].attendance_sqlite_id = data.attendance_sqlite_id;
      }
    }
  }

  getDuration(String clock_in_at) {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    DateTime clockInTime = dateFormat.parse(clock_in_at);
    Duration difference = DateTime.now().difference(clockInTime);

    int hours = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);
    return '$hours ${AppLocalizations.of(context)!.translate('hours')} $minutes ${AppLocalizations.of(context)!.translate('minutes')}';
  }
}