



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/transfer_owner.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../notifier/theme_color.dart';

class TransferRecord extends StatefulWidget {
  const TransferRecord({Key? key}) : super(key: key);

  @override
  State<TransferRecord> createState() => _TransferRecordState();
}

class _TransferRecordState extends State<TransferRecord> {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  late TextEditingController _controller;
  DateFormat dateFormat = DateFormat("dd/MM/yyyy");
  List<TransferOwner> transferOwnerList = [], dateTransferOwnerList = [];
  DateRangePickerController _dateRangePickerController = DateRangePickerController();
  String currentStDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String currentEdDate = new DateFormat("yyyy-MM-dd 00:00:00").format(DateTime.now());
  String _range = '', dateTimeNow = '';
  bool isLoaded = false;
  var deviceModel;

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    DateFormat _dateFormat = DateFormat("yyyy-MM-dd 00:00:00");
    if (args.value is PickerDateRange) {
      _range = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
      // ignore: lines_longer_than_80_chars
          ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';

      currentStDate = _dateFormat.format(args.value.startDate);
      currentEdDate = _dateFormat.format(args.value.endDate ?? args.value.startDate);
      _dateRangePickerController.selectedRange = PickerDateRange(args.value.startDate, args.value.endDate ?? args.value.startDate);
    }
  }

  @override
  void initState() {
    super.initState();
    dateTimeNow = dateFormat.format(DateTime.now());
    _controller = new TextEditingController(text: '${dateTimeNow} - ${dateTimeNow}');
    _dateRangePickerController.selectedRange = PickerDateRange(DateTime.now(), DateTime.now());
    preload();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
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
                          child: Text('Transfer owner record (${deviceModel})',
                              style: TextStyle(fontSize: 25, color: Colors.black)),
                        ),
                        Spacer(),
                        Container(
                            margin: EdgeInsets.only(right: 10),
                            child: IconButton(
                              onPressed: () {
                                showDialog(context: context, builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Select a date range'),
                                    content: Container(
                                      height: 350,
                                      width: 350,
                                      child: Container(
                                        child: Card(
                                          child: SfDateRangePicker(
                                            controller: _dateRangePickerController,
                                            selectionMode: DateRangePickerSelectionMode.range,
                                            onSelectionChanged: _onSelectionChanged,
                                            showActionButtons: true,
                                            onSubmit: (object) {
                                              dateTransferOwnerList.clear();
                                              _controller = new TextEditingController(text: '${_range}');
                                              preload();
                                              Navigator.of(context).pop();
                                            },
                                            onCancel: (){
                                              Navigator.of(context).pop();
                                            },

                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              },
                              icon: Icon(Icons.calendar_month),
                            )),
                        Container(
                          width: 300,
                          child: TextField(
                            controller: _controller,
                            enabled: false,
                          ),
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
            body: Container(
              padding: const EdgeInsets.all(8.0),
              child: Text('this is daily sales'),
            ),
          );
        }
      });
    });
  }

  preload() async {
    await getDeviceName();
    getAllTransferRecord();
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
    setState(() {
      isLoaded = true;
    });
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
