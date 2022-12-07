import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/object/receipt_layout.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../../translation/AppLocalizations.dart';

class CashDialog extends StatefulWidget {
  final bool isCashIn;
  final bool isCashOut;
  final bool isNewDay;
  final Function() callBack;
  const CashDialog({Key? key, required this.isCashIn, required this.callBack, required this.isCashOut, required this.isNewDay}) : super(key: key);

  @override
  State<CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<CashDialog> {
  final remarkController = TextEditingController();
  final amountController = TextEditingController();
  List<AppSetting> appSettingList = [];
  String amount = '';
  bool _isLoad = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    readLastSettlement();
    getAllAppSetting();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    remarkController.dispose();
    amountController.dispose();
  }

  String? get errorRemark {
    final text = remarkController.value.text;
    if (text.isEmpty && widget.isNewDay == false) {
      return 'remark_required';
    }
    return null;
  }

  String? get errorAmount {
    final text = amountController.value.text;
    if (text.isEmpty) {
      return 'amount_required';
    }
    return null;
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);
    if (errorRemark == null && errorAmount == null) {
      if (widget.isCashIn) {
        print('cash in');
        createCashRecord(1);
      } else if(widget.isCashOut) {
        print('cash-out');
        createCashRecord(2);
      } else {
        createCashRecord(3);
      }
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if(constraints.maxWidth > 800){
                return AlertDialog(
                  title: widget.isNewDay ? Text('Opening Balance') : widget.isCashIn ? Text('Cash-in') :  Text('Cash-out'),
                  content: Container(
                    height: widget.isNewDay ? MediaQuery.of(context).size.height / 6 : MediaQuery.of(context).size.height / 4,
                    width: widget.isNewDay ? MediaQuery.of(context).size.height / 2 : MediaQuery.of(context).size.width / 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Visibility(
                              visible: widget.isNewDay ? false : true,
                              child: ValueListenableBuilder(
                                // Note: pass _controller to the animation argument
                                  valueListenable: remarkController,
                                  builder: (context, TextEditingValue value, __) {
                                    return SizedBox(
                                      height: 100,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller: remarkController,
                                          decoration: InputDecoration(
                                            errorText: _submitted
                                                ? errorRemark == null
                                                ? errorRemark
                                                : AppLocalizations.of(context)
                                                ?.translate(errorRemark!)
                                                : null,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: color.backgroundColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: color.backgroundColor),
                                            ),
                                            labelText: 'Remark',
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ),
                          Container(
                            child: ValueListenableBuilder(
                              // Note: pass _controller to the animation argument
                                valueListenable: amountController,
                                builder: (context, TextEditingValue value, __) {
                                  return SizedBox(
                                    height: 85,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                        keyboardType: TextInputType.number,
                                        controller: amountController,
                                        decoration: InputDecoration(
                                          errorText: _submitted
                                              ? errorAmount == null
                                              ? errorAmount
                                              : AppLocalizations.of(context)
                                              ?.translate(errorAmount!)
                                              : null,
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: color.backgroundColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: color.backgroundColor),
                                          ),
                                          labelText: 'Amount',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                          widget.isNewDay && _isLoad && this.amount != '' ?
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              alignment: Alignment.topLeft,
                              height: MediaQuery.of(context).size.height / 18,
                              child: Row(
                                children: [
                                  Container(
                                      child: Text('Last settlement opening balance: ${amount}')
                                  ),
                                  Spacer(),
                                  Container(
                                      child: ElevatedButton(
                                        child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                                        onPressed: (){
                                          amountController.text = amount;
                                        },
                                        style: ElevatedButton.styleFrom(primary: color.backgroundColor),
                                      )
                                  )
                                ],
                              )
                          ) :
                          Container()
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    widget.isNewDay ? Container() :
                    TextButton(
                      child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                      onPressed: (){
                        closeDialog(context);
                      },
                    ),
                    TextButton(
                      child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                      onPressed: (){
                        _submit(context);
                      },
                    )
                  ],
                );
              } else {
                //mobile layout
                return Center(
                  child: SingleChildScrollView(
                    child: AlertDialog(
                      title: widget.isNewDay ? Text('Opening Balance') : widget.isCashIn ? Text('Cash-in') :  Text('Cash-out'),
                      content: Container(
                        height: widget.isNewDay ? MediaQuery.of(context).size.height / 3 : 150,
                        width: widget.isNewDay ? MediaQuery.of(context).size.height / 1 : MediaQuery.of(context).size.width / 2,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Visibility(
                                  visible: widget.isNewDay ? false : true,
                                  child: ValueListenableBuilder(
                                    // Note: pass _controller to the animation argument
                                      valueListenable: remarkController,
                                      builder: (context, TextEditingValue value, __) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextField(
                                            autofocus: true,
                                            controller: remarkController,
                                            decoration: InputDecoration(
                                              errorText: _submitted
                                                  ? errorRemark == null
                                                  ? errorRemark
                                                  : AppLocalizations.of(context)
                                                  ?.translate(errorRemark!)
                                                  : null,
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: color.backgroundColor),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: color.backgroundColor),
                                              ),
                                              labelText: 'Remark',
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                              ),
                              Container(
                                child: ValueListenableBuilder(
                                  // Note: pass _controller to the animation argument
                                    valueListenable: amountController,
                                    builder: (context, TextEditingValue value, __) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                          keyboardType: TextInputType.number,
                                          controller: amountController,
                                          decoration: InputDecoration(
                                            errorText: _submitted
                                                ? errorAmount == null
                                                ? errorAmount
                                                : AppLocalizations.of(context)
                                                ?.translate(errorAmount!)
                                                : null,
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: color.backgroundColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: color.backgroundColor),
                                            ),
                                            labelText: 'Amount',
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                              Visibility(
                                visible: widget.isNewDay && _isLoad && this.amount != '' ? true : false,
                                child: Container(
                                    margin: EdgeInsets.only(left: 10),
                                    alignment: Alignment.topLeft,
                                    height: MediaQuery.of(context).size.height / 9,
                                    child: Row(
                                      children: [
                                        Container(
                                            child: Text('Last settlement opening balance: ${amount}')
                                        ),
                                        Spacer(),
                                        Container(
                                            child: ElevatedButton(
                                              child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                                              onPressed: (){
                                                amountController.text = amount;
                                              },
                                              style: ElevatedButton.styleFrom(primary: color.backgroundColor),
                                            )
                                        )
                                      ],
                                    )
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        widget.isNewDay ? Container() :
                        TextButton(
                          child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                          onPressed: (){
                            closeDialog(context);
                          },
                        ),
                        TextButton(
                          child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                          onPressed: (){
                            _submit(context);
                          },
                        )
                      ],
                    ),
                  ),
                );
              }
            }
          ),
        ),
      );
    });
  }

/*
  ----------------DB Query part------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  createCashRecord(int type) async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? pos_user = prefs.getString('pos_pin_user');
      final String? login_user = prefs.getString('user');
      Map userObject = json.decode(pos_user!);
      Map logInUser = json.decode(login_user!);

      CashRecord cashRecordObject  = CashRecord(
          cash_record_id: 0,
          company_id: logInUser['company_id'].toString(),
          branch_id: branch_id.toString(),
          remark: widget.isNewDay ? 'opening balance' : remarkController.text,
          amount: amountController.text,
          payment_name: '',
          payment_type_id: '',
          type: widget.isNewDay ? 0 : type,
          user_id: userObject['user_id'].toString(),
          settlement_date: '',
          sync_status: 0,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''
      );

      CashRecord data = await PosDatabase.instance.insertSqliteCashRecord(cashRecordObject);
      widget.callBack();
      closeDialog(context);
      if(widget.isNewDay){
        if(appSettingList.length > 0 && appSettingList[0].open_cash_drawer == 1){
          ReceiptLayout().openCashDrawer();
        }
      } else {
        ReceiptLayout().openCashDrawer();
      }

    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create cash record error: ${e}");
    }
  }

  getAllAppSetting() async {
    List<AppSetting> data = await PosDatabase.instance.readAllAppSetting();
    if(data.length > 0){
      appSettingList = List.from(data);
    }
  }

  readLastSettlement() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<CashRecord> data = await PosDatabase.instance.readSpecificLatestSettlementCashRecord(branch_id.toString());
    if(data.length > 0){
      amount = data[0].amount!;
    }

    setState(() {
      _isLoad = true;
    });

  }
}
