import 'package:flutter/material.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' as Platform;

import '../../notifier/report_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/report_class.dart';

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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            child: Text(AppLocalizations.of(context)!.translate('transfer_owner_report')+' (${deviceModel})',
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
                      dateTransferOwnerList.isNotEmpty
                          ?
                      Expanded(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dateTransferOwnerList.length,
                            itemBuilder: (BuildContext context,int index){
                              return Card(
                                elevation: 5,
                                child: ListTile(
                                  title: Text(AppLocalizations.of(context)!.translate('from')+': ${dateTransferOwnerList[index].fromUsername} to ${dateTransferOwnerList[index].toUsername}'),
                                  subtitle: Text(AppLocalizations.of(context)!.translate('transfer_date_time')+': ${Utils.formatDate(dateTransferOwnerList[index].created_at)}'),
                                  leading:  CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.compare_arrows, color: Colors.grey,)),
                                  trailing: Text('${dateTransferOwnerList[index].cash_balance}'),
                                ),
                              );
                            }
                        ),
                      )
                      :
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
              ) : CustomProgressBar();
            } else {
              ///mobile layout
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
                            child: Text(AppLocalizations.of(context)!.translate('transfer_owner_report')+' (${deviceModel})',
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
                                  title: Text(AppLocalizations.of(context)!.translate('from')+': ${dateTransferOwnerList[index].fromUsername} to ${dateTransferOwnerList[index].toUsername}'),
                                  subtitle: Text(AppLocalizations.of(context)!.translate('transfer_date_time')+': ${dateTransferOwnerList[index].created_at}'),
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
    ReportObject object = await ReportObject().getAllTransferRecord(currentStDate: currentStDate, currentEdDate: currentEdDate);
    dateTransferOwnerList = object.dateTransferList!;
  }

  addDays({date}){
    var _date = date.add(Duration(days: 1));
    return _date;
  }

  getDeviceName() async {
    if (Platform.Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceModel = androidInfo.model;
  }
    else if(Platform.Platform.isIOS){
      deviceModel = 'IOS Device';
    }
    else{
      deviceModel = 'Web';
    }
  }
}
