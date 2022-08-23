import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/domain.dart';
import '../notifier/theme_color.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../object/branch.dart';

class ChooseBranch extends StatefulWidget {
  final Function(Branch) callBack;
  final Branch? preSelectBranch;

  const ChooseBranch({Key? key, required this.callBack, this.preSelectBranch})
      : super(key: key);

  @override
  _ChooseBranchState createState() => _ChooseBranchState();
}

class _ChooseBranchState extends State<ChooseBranch> {
  Branch? selectedValue;
  List<Branch> list = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    showPreviousSelectBranch();
    getCompanyBranch();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Container(
        color: color.backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Choose your branch',
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
                                  'Choose your store',
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
                          // dropdownMaxHeight: 200,
                          iconEnabledColor: color.backgroundColor,
                          buttonPadding:
                              const EdgeInsets.only(left: 14, right: 14),
                          buttonHeight: 55,
                          isExpanded: true,
                          dropdownMaxHeight: 200,
                          scrollbarThickness: 8,
                          dropdownOverButton: true,
                          dropdownDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.grey.shade100,
                          ),
                          scrollbarRadius: Radius.circular(60),
                          buttonDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.grey.shade100,
                          ),
                          items: list
                              .map((branch) => DropdownMenuItem<Branch>(
                                    value: branch,
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
                                            branch.name!,
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
                          onChanged: (Branch? value) {
                            setState(() {
                              selectedValue = value;
                              saveBranch();
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

  getCompanyBranch() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getCompanyBranch(userObject['company_id']);
    if (data['status'] == '1') {
      setState(() {
        List responseJson = data['branch'];
        list.addAll(responseJson
            .map((jsonObject) => Branch.fromJson(jsonObject))
            .toList());
      });
    }
  }

  saveBranch() {
    widget.callBack(selectedValue!);
    print(selectedValue!.toJson());
    print(list);
  }
  showPreviousSelectBranch(){
    setState(() {
      if ( widget.preSelectBranch!= null) {
        // selectedValue = widget.preSelectBranch;
        print(widget.preSelectBranch!.toJson());
        print(list);
      }
      else{
        selectedValue = null;
      }
    });
  }
}
