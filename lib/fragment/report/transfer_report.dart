import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';

class TransferRecord extends StatefulWidget {
  const TransferRecord({Key? key}) : super(key: key);

  @override
  State<TransferRecord> createState() => _TransferRecordState();
}

class _TransferRecordState extends State<TransferRecord> {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  List<TransferOwner> transferOwnerList = [], dateTransferOwnerList = [];
  String currentStDate = '';
  String currentEdDate = '';
  bool isLoaded = false;
  var deviceModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(reportModel.load == 0){
            preload(reportModel);
            reportModel.setLoaded();
          }
        });
          return LayoutBuilder(builder: (context, constraints) {
            if(constraints.maxWidth > 800){
              return isLoaded ?
              Scaffold(
                resizeToAvoidBottomInset: false,
                body: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              child: Text('Transfer Owner Report (${deviceModel})',
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
                        Expanded(
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: dateTransferOwnerList.length,
                              itemBuilder: (BuildContext context,int index){
                                return Card(
                                  elevation: 5,
                                  child: ListTile(
                                    title: Text('From: ${dateTransferOwnerList[index].fromUsername} to ${dateTransferOwnerList[index].toUsername}'),
                                    subtitle: Text('Transfer date time: ${dateTransferOwnerList[index].created_at}'),
                                    leading:  CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.compare_arrows, color: Colors.grey,)),
                                    trailing: Text('${dateTransferOwnerList[index].cash_balance}'),
                                  ),
                                );
                              }
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ) : CustomProgressBar();
            } else {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                body: this.isLoaded ?
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text('Transfer Owner Report (${deviceModel})',
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
                      Expanded(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dateTransferOwnerList.length,
                            itemBuilder: (BuildContext context,int index){
                              return Card(
                                elevation: 5,
                                child: ListTile(
                                  title: Text('From: ${dateTransferOwnerList[index].fromUsername} to ${dateTransferOwnerList[index].toUsername}'),
                                  subtitle: Text('Transfer date time: ${dateTransferOwnerList[index].created_at}'),
                                  leading:  CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.compare_arrows, color: Colors.grey,)),
                                  trailing: Text('${dateTransferOwnerList[index].cash_balance}'),
                                ),
                              );
                            }
                        ),
                      )
                    ],
                  ),
                ) : CustomProgressBar(),
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
    await getDeviceName();
    await getAllTransferRecord();
    if(mounted){
      setState(() {
        isLoaded = true;
      });
    }
  }

  getAllTransferRecord() async {
    DateTime _startDate = DateTime.parse(currentStDate);
    DateTime _endDate = DateTime.parse(currentEdDate);
    List<TransferOwner> data = await PosDatabase.instance.readAllTransferOwner();
    if(data.isNotEmpty){
      transferOwnerList = data;
      for(int i = 0; i < transferOwnerList.length; i++){
        DateTime convertDate = new DateFormat("yyyy-MM-dd HH:mm:ss").parse(transferOwnerList[i].created_at!);
        if(currentStDate != currentEdDate){
          if(convertDate.isAfter(_startDate)){
            if(convertDate.isBefore(addDays(date: _endDate))){
              dateTransferOwnerList.add(transferOwnerList[i]);
            }
          }
        } else {
          if(convertDate.isAfter(_startDate) && convertDate.isBefore(addDays(date: _endDate))){
            dateTransferOwnerList.add(transferOwnerList[i]);
          }
        }
      }
    }
  }

  addDays({date}){
    var _date = date.add(Duration(days: 1));
    return _date;
  }

  getDeviceName() async {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceModel = androidInfo.model;
  }
}
