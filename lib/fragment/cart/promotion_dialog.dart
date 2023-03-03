import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_promotion.dart';
import '../../translation/AppLocalizations.dart';

class PromotionDialog extends StatefulWidget {
  const PromotionDialog({Key? key}) : super(key: key);

  @override
  State<PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<PromotionDialog> {
  List<Promotion> promotionList = [];
  double dStartTime = 0.0;
  double dEndTime = 0.0;
  double dCurrentTime = 0.0;
  bool isActive = false;
  TimeOfDay currentTime = TimeOfDay.now();
  late DateTime startDTime;
  late DateTime endDTime;
  late TimeOfDay startTime;
  late TimeOfDay endTime;


  @override
  void initState() {
    super.initState();
    readAllPromotion();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text("Select Promotion"),
        content: Container(
          width: 350,
          height: 350,
          child: Consumer<CartModel>(builder: (context, CartModel cart, child) {
            return Column(
              children: [
                Expanded(
                    child: ListView.builder(
                        itemCount: promotionList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            elevation: 5,
                            child: ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.discount,
                                    color: Colors.grey,
                                  )),
                              title: Text('${promotionList[index].name}'),
                              onTap: () {
                                if(cart.cartNotifierItem.isNotEmpty){
                                  if(promotionList[index].all_time == '0') {
                                    checkOfferTime(promotionList[index]);
                                    isActive == true ?
                                    cart.addPromotion(promotionList[index]) :
                                    Fluttertoast.showToast(
                                        backgroundColor: Color(0xFFFF0000),
                                        msg: "${AppLocalizations.of(context)?.translate('offer_ended')}");
                                  }else{
                                    cart.addPromotion(promotionList[index]);
                                  }
                                  Navigator.of(context).pop();
                                }else{
                                  Fluttertoast.showToast(
                                      backgroundColor: Color(0xFFFF0000),
                                      msg: "${AppLocalizations.of(context)?.translate("empty_cart")}");

                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          );
                        }))
              ],
            );
          }),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  void checkOfferTime(Promotion promotion){
    try{
      currentTime = TimeOfDay.now();
      isActive = false;
      dateTimeConvert(promotion.stime!, promotion.etime!);
      double compareEndTime =  dEndTime - dCurrentTime;
      double compareStartTime = dCurrentTime - dStartTime;
      if(compareStartTime >= 0 && compareEndTime > 0){
        isActive = true;

      }else{
        isActive = false;
      }

    }catch(error){
      print('Check offer error: $error');
    }
  }

  dateTimeConvert(String stime, String etime){
    startDTime = new DateFormat("hh:mm").parse(stime);
    endDTime = new DateFormat("hh:mm").parse(etime);

    startTime = new TimeOfDay.fromDateTime(startDTime);
    endTime = new TimeOfDay.fromDateTime(endDTime);

    dStartTime = startTime.hour.toDouble() + (startTime.minute.toDouble() / 60);
    dEndTime = endDTime.hour.toDouble() + (endDTime.minute.toDouble()/60);
    dCurrentTime = currentTime.hour.toDouble() + (currentTime.minute.toDouble()/60);
  }

  void readAllPromotion() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkPromotion> data = await PosDatabase.instance.readBranchLinkPromotion(branch_id.toString());
    for (int i = 0; i < data.length; i++) {
      List<Promotion> result = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
      for (int j = 0; j < result.length; j++) {
        if (result[j].auto_apply == '0') {
          setState(() {
            promotionList.add(result[j]);
          });
        }
      }
    }
  }
}
