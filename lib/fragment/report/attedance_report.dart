import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:pos_system/object/attendance.dart';
import 'package:pos_system/object/categories.dart';
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

  @override
  void initState() {
    super.initState();
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
    ReportObject object = await ReportObject().getAllAttendanceGroup(currentStDate: currentStDate, currentEdDate: currentEdDate);
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
}
