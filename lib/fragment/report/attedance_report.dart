import 'dart:async';
import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/attendance.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';
import '../../page/progress_bar.dart';

class AttendanceReport extends StatefulWidget {
  const AttendanceReport({Key? key}) : super(key: key);

  @override
  State<AttendanceReport> createState() => _AttendanceReportState();
}

class _AttendanceReportState extends State<AttendanceReport> {
  List<DataRow> _dataRow = [];
  List<Categories> categoryData = [];
  List<Attendance> attendanceGroupData = [];
  String currentStDate = '';
  String currentEdDate = '';
  bool isLoaded = false;
  final List<String> allUser = ['all_staff'];
  int? selectedId = 0;
  StreamController actionController = StreamController();
  late Stream actionStream;

  @override
  void initState() {
    super.initState();
    getAllStaff();
    actionStream = actionController.stream.asBroadcastStream();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child){
        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: FutureBuilder(future: preload(reportModel), builder: (context, snapshot){
                if(snapshot.hasData){
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                child: Text(AppLocalizations.of(context)!.translate('attendance_report'),
                                    style: TextStyle(fontSize: 25, color: Colors.black)),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Divider(
                            height: 10,
                            color: Colors.grey,
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2(
                              isExpanded: true,
                              buttonStyleData: ButtonStyleData(
                                height: 55,
                                width: 200,
                                padding: const EdgeInsets.only(left: 14, right: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Colors.black26,
                                  ),
                                ),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade100,
                                ),
                                scrollbarTheme: ScrollbarThemeData(
                                    thickness: WidgetStateProperty.all(5),
                                    mainAxisMargin: 20,
                                    crossAxisMargin: 5
                                ),
                              ),
                              items: allUser.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                value: int.tryParse(sort.value.split(':').first) ?? sort.key,
                                child: Text(sort.value.contains(':') ? sort.value.split(':').last : AppLocalizations.of(context)!.translate(sort.value),
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              )).toList(),
                              value: selectedId,
                              onChanged: (int? value) {
                                setState(() {
                                  selectedId = value;
                                  print("selectedId: $selectedId");
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 5),
                          _dataRow.isNotEmpty ?
                          Container(
                            margin: EdgeInsets.all(10),
                            child: SingleChildScrollView(
                              child: DataTable(
                                  border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                  headingTextStyle: TextStyle(color: Colors.white),
                                  headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                  columns: <DataColumn>[
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('user'),
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(AppLocalizations.of(context)!.translate('clock_in'),
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('clock_out'),
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('hour_minute'),
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: _dataRow
                              ),
                            )
                          ):
                          Center(
                            heightFactor: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.menu),
                                Text(AppLocalizations.of(context)!.translate('no_record_found')),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                } else {
                  return CustomProgressBar();
                }
              })
            );
          } else {
            ///mobile layout
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: FutureBuilder(
                  future: preload(reportModel),
                  builder: (context, snapshot){
                    if(snapshot.hasData){
                      return Container(
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    child: Text(AppLocalizations.of(context)!.translate('attendance_report'),
                                        style: TextStyle(fontSize: 25, color: Colors.black)),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Divider(
                                height: 10,
                                color: Colors.grey,
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 55,
                                    width: 200,
                                    padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                        thickness: WidgetStateProperty.all(5),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 5
                                    ),
                                  ),
                                  items: allUser.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                    value: int.tryParse(sort.value.split(':').first) ?? sort.key,
                                    child: Text(sort.value.contains(':') ? sort.value.split(':').last : AppLocalizations.of(context)!.translate(sort.value),
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: selectedId,
                                  onChanged: (int? value) {
                                    setState(() {
                                      selectedId = value;
                                      print("selectedId: $selectedId");
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 5),
                              _dataRow.isNotEmpty ?
                              Container(
                                  margin: EdgeInsets.all(10),
                                  child:
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                        border: TableBorder.symmetric(outside: BorderSide(color: Colors.black12)),
                                        headingTextStyle: TextStyle(color: Colors.white),
                                        headingRowColor: MaterialStateColor.resolveWith((states) {return Colors.black;},),
                                        columns: <DataColumn>[
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('user'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(AppLocalizations.of(context)!.translate('clock_in'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('clock_out'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.translate('hour_minute'),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: _dataRow
                                    ),
                                  )
                              ):
                              Center(
                                heightFactor: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.menu),
                                    Text(AppLocalizations.of(context)!.translate('no_record_found')),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    } else {
                      return CustomProgressBar();
                    }
                  })
            );
          }
        });
      }
      );
    });
  }

  preload(ReportModel reportModel) async {
    this.currentStDate = reportModel.startDateTime;
    this.currentEdDate = reportModel.endDateTime;
    await getAllProductWithOrder();
    reportModel.addOtherValue(valueList: attendanceGroupData);
    return _dataRow;
  }

  getAllProductWithOrder() async {
    _dataRow.clear();
    ReportObject object = await ReportObject().getAllAttendanceGroup(currentStDate: currentStDate, currentEdDate: currentEdDate, selectedId: selectedId);
    attendanceGroupData = object.dateAttendance!;
    if(attendanceGroupData.isNotEmpty){
      for(int i = 0; i < attendanceGroupData.length; i++){
        ReportObject object2 = await ReportObject().getAllAttendance(userId: attendanceGroupData[i].user_id, currentStDate: currentStDate, currentEdDate: currentEdDate);
        attendanceGroupData[i].groupAttendanceList = object2.dateAttendance!;
        _dataRow.addAll([
          DataRow(
            color: MaterialStateColor.resolveWith((states) {return Colors.grey;},),
            cells: <DataCell>[
              DataCell(Text('${attendanceGroupData[i].userName}', style: TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(getDuration(attendanceGroupData[i].totalDuration)))
            ],
          ),
          for(int j = 0; j < attendanceGroupData[i].groupAttendanceList.length; j++)
            DataRow(
              cells: <DataCell>[
                DataCell(Text('${j+1}')),
                DataCell(Text('${attendanceGroupData[i].groupAttendanceList[j].clock_in_at}')),
                DataCell(Text('${attendanceGroupData[i].groupAttendanceList[j].clock_out_at}')),
                DataCell(Text(getDuration(attendanceGroupData[i].groupAttendanceList[j].duration)))
              ],
            ),
        ]);
      }
    }
  }

  String getDuration(int? duration) {
    if (duration == null || duration == 0) {
      return '-';
    }

    int hours = duration ~/ 60;
    int minutes = duration % 60;

    return '${hours > 0 ? '$hours ${AppLocalizations.of(context)!.translate('hours')}' : ''} ${minutes > 0 ? '$minutes ${AppLocalizations.of(context)!.translate('minutes')}' : ''}';
  }

  getAllStaff() async {
    List<User>users = await PosDatabase.instance.readAllUser();
    // allUser.addAll(users.map((user) => user.user_id.toString()).toList());
    allUser.addAll(users.map((user) => '${user.user_id}:${user.name!}').toList());
  }
}
