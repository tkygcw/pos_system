import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class CashDialog extends StatefulWidget {
  final bool isCashIn;
  final bool isCashOut;
  final Function() callBack;
  const CashDialog({Key? key, required this.isCashIn, required this.callBack, required this.isCashOut}) : super(key: key);

  @override
  State<CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<CashDialog> {
  final remarkController = TextEditingController();
  final amountController = TextEditingController();
  bool _submitted = false;


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    remarkController.dispose();
    amountController.dispose();
  }

  String? get errorRemark {
    final text = remarkController.value.text;
    if (text.isEmpty) {
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
      return AlertDialog(
        title: widget.isCashIn ? Text('Cash-in') : Text('Cash-out'),
        content: Container(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
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
                Container(
                  child: ValueListenableBuilder(
                    // Note: pass _controller to the animation argument
                      valueListenable: amountController,
                      builder: (context, TextEditingValue value, __) {
                        return SizedBox(
                          height: 100,
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
              ],
            ),
          ),
        ),
        actions: [
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
    });
  }

  createCashRecord(int type) async {
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);

      CashRecord cashRecordObject  = CashRecord(
          cash_record_id: 0,
          company_id: '6',
          branch_id: branch_id.toString(),
          remark: remarkController.text,
          amount: amountController.text,
          payment_name: '',
          payment_type_id: '',
          type: type,
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
    }catch(e){
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: "Create cash record error: ${e}");
    }
  }
}
