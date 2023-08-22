import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/cash_record.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/order.dart';
import '../../object/payment_link_company.dart';
import '../../translation/AppLocalizations.dart';
import '../logout_dialog.dart';
import 'make_payment_dialog.dart';


class PaymentSelect extends StatefulWidget {
  final String? dining_id;
  final String dining_name;
  final bool? isUpdate;
  final Order? currentOrder;
  const PaymentSelect(
      {
        Key? key,
        required this.dining_id,
        required this.dining_name,
        this.isUpdate,
        this.currentOrder
      }) : super(key: key);

  @override
  State<PaymentSelect> createState() => _PaymentSelectState();
}

class _PaymentSelectState extends State<PaymentSelect> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  String? order_value, cash_record_value;
  String currentMethod = '';
  List<PaymentLinkCompany> PaymentLists = [];
  Order? order;
  bool isload = false, isLogOut = false, willPop = true, isButtonDisable = false;

  @override
  void initState() {
    super.initState();
    order = widget.currentOrder;
    readPaymentMethod();
    if(widget.isUpdate != null){
      readCurrentOrderPaymentType();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartModel>(builder: (context, CartModel cart, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 800){
          return WillPopScope(
            onWillPop: () async => willPop ,
            child: AlertDialog(
              title: Text(AppLocalizations.of(context)!.translate('select_payment_method')),
              content: isload ? Container(
                // width: MediaQuery.of(context).size.width / 2,
                // height: MediaQuery.of(context).size.height / 2,
                  child: Container(
                    margin: EdgeInsets.all(2),
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 3,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Visibility(
                            visible: currentMethod != ''? true : false,
                            child: Text(AppLocalizations.of(context)!.translate('current_payment_method')+': ${currentMethod}'),
                          ),
                          GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 4,
                              children: List.generate(PaymentLists.length, (index) {
                                return GestureDetector(
                                  onTap: () async {
                                    if(widget.isUpdate == null){
                                      openMakePayment(PaymentLists[index].type!, PaymentLists[index].payment_link_company_id!, widget.dining_id!, widget.dining_name);
                                    } else {
                                      setState(() {
                                        willPop = false;
                                        isButtonDisable = true;
                                      });
                                      if(order?.payment_link_company_id != PaymentLists[index].payment_link_company_id.toString()){
                                        await updatePaymentMethod(paymentLinkCompany: PaymentLists[index]);
                                        if(isLogOut){
                                          openLogOutDialog();
                                        }
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                        cart.changInit(true);
                                        Fluttertoast.showToast(
                                            backgroundColor: Colors.green,
                                            msg: "${AppLocalizations.of(context)?.translate('update_success')}");
                                      } else {
                                        setState(() {
                                          willPop = true;
                                          isButtonDisable = false;
                                        });
                                        Fluttertoast.showToast(
                                            backgroundColor: Colors.orangeAccent,
                                            msg: "${AppLocalizations.of(context)?.translate('same_payment_method_error')}");
                                      }
                                    }
                                  },
                                  child: Card(
                                    elevation: 5,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: Container(
                                      height: MediaQuery.of(context).size.height / 3,
                                      width: MediaQuery.of(context).size.width / 3,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // ClipRRect(
                                          //   borderRadius: BorderRadius.circular(16.0),
                                          //   child:///***If you have exported images you must have to copy those images in assets/images directory.
                                          //   Image(
                                          //     image: AssetImage("drawable/payment_method.png"),
                                          //     // NetworkImage(
                                          //     //     "https://image.freepik.com/free-photo/close-up-people-training-with-ball_23-2149049821.jpg"),
                                          //     height: MediaQuery.of(context).size.height,
                                          //     width: MediaQuery.of(context).size.width,
                                          //     fit: BoxFit.cover,
                                          //   ),
                                          // ),
                                          Text(
                                            '${PaymentLists[index].name}',
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 16,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                          ),
                    ]),
                  ))
                  : CustomProgressBar(),
              actions: [
                ElevatedButton(
                    onPressed: isButtonDisable ? null : (){
                      setState(() {
                        isButtonDisable = true;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.translate('close')))
              ],
            ),
          );
        } else {
          ///mobile view
          return Center(
            child: WillPopScope(
              onWillPop: () async => willPop,
              child: AlertDialog(
                title: Text(AppLocalizations.of(context)!.translate('select_payment_method')),
                content: isload ? Container(
                  margin: EdgeInsets.all(2),
                  width: MediaQuery.of(context).size.width / 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: currentMethod != ''? true : false,
                        child: Text(AppLocalizations.of(context)!.translate('current_payment_method')+': ${currentMethod}'),
                      ),
                      SizedBox(height: 10,),
                      GridView.count(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          children: List.generate(PaymentLists.length, (index) {
                            return GestureDetector(
                              onTap: () async  {
                                if(widget.isUpdate == null){
                                  openMakePayment(PaymentLists[index].type!, PaymentLists[index].payment_link_company_id!, widget.dining_id!, widget.dining_name);
                                } else {
                                  setState(() {
                                    willPop = false;
                                    isButtonDisable = true;
                                  });
                                  if(order?.payment_link_company_id != PaymentLists[index].payment_link_company_id.toString()){
                                    await updatePaymentMethod(paymentLinkCompany: PaymentLists[index]);
                                    if(isLogOut){
                                      openLogOutDialog();
                                    }
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    cart.changInit(true);
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.green,
                                        msg: "${AppLocalizations.of(context)?.translate('update_success')}");
                                  } else {
                                    setState(() {
                                      willPop = true;
                                      isButtonDisable = false;
                                    });
                                    Fluttertoast.showToast(
                                        backgroundColor: Colors.orangeAccent,
                                        msg: "${AppLocalizations.of(context)?.translate('same_payment_method_error')}");
                                  }
                                }

                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Container(
                                  height: MediaQuery.of(context).size.height / 3,
                                  width: MediaQuery.of(context).size.width / 3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // ClipRRect(
                                      //   borderRadius: BorderRadius.circular(16.0),
                                      //   child:///***If you have exported images you must have to copy those images in assets/images directory.
                                      //   Image(
                                      //     image: AssetImage("drawable/payment_method.png"),
                                      //     // NetworkImage(
                                      //     //     "https://image.freepik.com/free-photo/close-up-people-training-with-ball_23-2149049821.jpg"),
                                      //     height: MediaQuery.of(context).size.height,
                                      //     width: MediaQuery.of(context).size.width,
                                      //     fit: BoxFit.cover,
                                      //   ),
                                      // ),
                                      Text(
                                        '${PaymentLists[index].name}',
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 16,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                      ),
                    ],
                  )
                )
                    : CustomProgressBar(),
                actions: [
                  ElevatedButton(
                      onPressed: isButtonDisable ? null : (){
                        setState(() {
                          isButtonDisable = true;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.translate('close')))
                ],
              ),
            ),
          );
        }
      });
    });
  }

  updatePaymentMethod({required PaymentLinkCompany paymentLinkCompany}) async {
    await updateCashRecordPaymentType(selectedPaymentType: paymentLinkCompany.payment_type_id!);
    await updateOrderPaymentMethod(selectedPaymentLinkCompanyId: paymentLinkCompany.payment_link_company_id.toString());
    await syncAllToCloud();
  }

  updateCashRecordPaymentType({required String selectedPaymentType}) async {
    List<String> _value = [];
    String dateTime = dateFormat.format(DateTime.now());
    String orderNumber = order?.generateOrderNumber();
    //get cash record by order number or remark
    CashRecord? cashRecord = await PosDatabase.instance.readSpecificCashRecordByRemark(orderNumber);

    CashRecord data = CashRecord(
      updated_at: dateTime,
      sync_status: cashRecord!.sync_status == 0 ? 0 : 2,
      payment_type_id: selectedPaymentType,
      cash_record_key: cashRecord.cash_record_key,
    );

    int status = await PosDatabase.instance.updatePaymentTypeId(data);
    if (status == 1) {
      CashRecord updatedData = await PosDatabase.instance.readSpecificCashRecord(cashRecord.cash_record_sqlite_id!);
      _value.add(jsonEncode(updatedData));
    }
    cash_record_value = _value.toString();
  }

  updateOrderPaymentMethod({required String selectedPaymentLinkCompanyId}) async {
    try{
      List<String> _value = [];
      String dateTime = dateFormat.format(DateTime.now());
      Order? checkData = await PosDatabase.instance.readSpecificOrder(order!.order_sqlite_id!);
      Order data = Order(
        updated_at: dateTime,
        sync_status: checkData.sync_status == 0 ? 0 : 2,
        payment_link_company_id: selectedPaymentLinkCompanyId,
        order_key: order!.order_key,
      );
      int status = await PosDatabase.instance.updatePaymentMethod(data);
      if (status == 1) {
        Order orderData = await PosDatabase.instance.readSpecificOrder(order!.order_sqlite_id!);
        _value.add(jsonEncode(orderData));
      }
      order_value = _value.toString();
    } catch(e){
      print("update payment method error: $e)");
    }
  }

  readPaymentMethod() async {
    //read available payment method
    List<PaymentLinkCompany> data = await PosDatabase.instance.readPaymentMethods();
    PaymentLists = List.from(data);
    setState(() {
      isload = true;
    });
  }

  readCurrentOrderPaymentType() async {
    int id = int.parse(widget.currentOrder!.payment_link_company_id!);
    PaymentLinkCompany? data = await PosDatabase.instance.readSpecificPaymentLinkCompany(id);
    if(data != null){
      currentMethod = data.name!;
    }
  }

  Future<Future<Object?>> openMakePayment(int type_id, int payment_link_id, String dining, String diningName) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: MakePayment(
                dining_id: dining,
                dining_name: diningName,
                type: type_id,
                payment_link_company_id: payment_link_id,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }


  syncAllToCloud() async {
    try{
      if(mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
          device_id: device_id.toString(),
          value: login_value,
          order_value: this.order_value,
          cash_record_value: this.cash_record_value
        );
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for(int i = 0; i < responseJson.length; i++){
            switch(responseJson[i]['table_name']){
              case 'tb_order': {
                await PosDatabase.instance.updateOrderSyncStatusFromCloud(responseJson[i]['order_key']);
              }
              break;
              case 'tb_cash_record': {
                await PosDatabase.instance.updateCashRecordSyncStatusFromCloud(responseJson[i]['cash_record_key']);
              }
              break;
            }
          }
          mainSyncToCloud.resetCount();
        } else if(data['status'] == '7'){
          mainSyncToCloud.resetCount();
          isLogOut = true;
        }else if (data['status'] == '8'){
          print('payment time out');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Time out");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
      // bool _hasInternetAccess = await Domain().isHostReachable();
      // if (_hasInternetAccess) {
      //
      // }
    }catch(e){
      print('payment select sync to cloud error: $e');
      mainSyncToCloud.resetCount();
    }

  }

}
