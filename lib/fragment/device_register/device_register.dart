import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import '../../database/domain.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch.dart';
import '../../object/device.dart';

class DeviceRegister extends StatefulWidget {
  final Function(Device) callBack;
  final Branch? selectedBranch;

  const DeviceRegister({Key? key, required this.callBack, this.selectedBranch}) : super(key: key);

  @override
  _DeviceRegisterState createState() => _DeviceRegisterState();
}

class _DeviceRegisterState extends State<DeviceRegister> {
  Device? selectedValue;
  List<Device> list = [];

  @override
  void initState() {
    // selectedValue = widget.preSelectBranch as Branch;
    // TODO: implement initState
    super.initState();
    getBranchDevice();
    // if ( widget.preSelectBranch!= null) {
    //   print(widget.preSelectBranch.toString());
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Choose your device',
                style: TextStyle(color: color.iconColor, fontSize: 30),
              ),
            ),
            Container(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2(
                          isExpanded: true,
                          hint: Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 25,
                                color: color.backgroundColor,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Choose your device',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          buttonStyleData: ButtonStyleData(
                            height: 55,
                            padding: const EdgeInsets.only(left: 14, right: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.black26,
                              ),
                              color: Colors.grey.shade100,
                            ),
                            elevation: 2,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            isOverButton: true,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.grey.shade100,
                            ),
                            scrollbarTheme: ScrollbarThemeData(
                              radius: const Radius.circular(30),
                              thickness: WidgetStateProperty.all(8),
                            ),
                          ),
                          // dropdownMaxHeight: 200,
                          // iconEnabledColor: color.backgroundColor,
                          // buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                          // buttonHeight: 55,
                          // isExpanded: true,
                          // dropdownMaxHeight: 200,
                          // scrollbarThickness: 8,
                          // dropdownOverButton: true,
                          // dropdownDecoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(30),
                          //   color: Colors.grey.shade100,
                          // ),
                          // scrollbarRadius: Radius.circular(60),
                          // buttonDecoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(30),
                          //   color: Colors.grey.shade100,
                          // ),
                          items: list
                              .map((device) => DropdownMenuItem<Device>(
                                    value: device,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.store,
                                          size: 25,
                                          color: color.backgroundColor,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            device.name!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          value: selectedValue,
                          onChanged: (value) {
                            setState(() {
                              selectedValue = value as Device;
                              saveDevice();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  getBranchDevice() async {
    Map data = await Domain().getBranchDevice(widget.selectedBranch!.branchID.toString());
    if (data['status'] == '1') {
      setState(() {
        List responseJson = data['device'];
        list.addAll(responseJson.map((jsonObject) => Device.fromJson(jsonObject)).toList());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(AppLocalizations.of(context)!.translate('no_pos_device_is_set_in_this_branch')),
          action: SnackBarAction(
            label: 'Action',
            onPressed: () {
              // Code to execute.
            },
          ),
        ),
      );
    }
  }

  saveDevice() {
    widget.callBack(selectedValue!);
  }
}
