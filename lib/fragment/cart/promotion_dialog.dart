import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:provider/provider.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_promotion.dart';
import '../../translation/AppLocalizations.dart';

class PromotionDialog extends StatefulWidget {
  final String cartFinalAmount;
  const PromotionDialog({Key? key, required this.cartFinalAmount}) : super(key: key);

  @override
  State<PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<PromotionDialog> {
  List<Promotion> promotionList = [];
  double dStartTime = 0.0;
  double dEndTime = 0.0;
  double dCurrentTime = 0.0;
  bool isActive = false, _isLoaded = false;
  TimeOfDay currentTime = TimeOfDay.now();
  late DateTime startDTime;
  late DateTime endDTime;
  late TimeOfDay startTime;
  late TimeOfDay endTime;


  @override
  void initState() {
    super.initState();
    readAllPromotion();
    print('final amount = ${widget.cartFinalAmount}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('select_promotion')),
        content: Container(
          width: 350,
          height: 350,
          child: Consumer<CartModel>(builder: (context, CartModel cart, child) {
            return Column(
              children: [
                Expanded(
                    child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
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
                              trailing: promotionList[index].type == 0 ? 
                              Text('-${promotionList[index].amount}%'):
                              Text('-${double.parse(promotionList[index].amount!).toStringAsFixed(2)}'),
                              title: Text('${promotionList[index].name}'),
                              onTap: () {
                                bool outstanding = checkOfferAmount(promotionList[index]);
                                if(outstanding){
                                  Fluttertoast.showToast(
                                      backgroundColor: Color(0xFFFF0000),
                                      msg: AppLocalizations.of(context)!.translate('outstanding_promotion'));
                                } else {
                                  if(cart.cartNotifierItem.isNotEmpty){
                                    if(promotionList[index].specific_category == '1'){
                                      bool hasCategoryDiscount = cart.cartNotifierItem.any((item) => item.category_id == promotionList[index].category_id);
                                      if(hasCategoryDiscount){
                                        if(promotionList[index].all_time == '0') {
                                          checkOfferTime(promotionList[index]);
                                          isActive == true ?
                                          cart.addPromotion(promotionList[index]) :
                                          Fluttertoast.showToast(
                                              backgroundColor: Color(0xFFFF0000),
                                              msg: "${AppLocalizations.of(context)?.translate('offer_ended')}");
                                        } else {
                                          cart.addPromotion(promotionList[index]);
                                        }
                                      } else {
                                        Fluttertoast.showToast(
                                            backgroundColor: Color(0xFFFF0000),
                                            msg: AppLocalizations.of(context)!.translate('no_product_match_with_promotion_category'));
                                      }
                                    } else {
                                      if(promotionList[index].all_time == '0') {
                                        checkOfferTime(promotionList[index]);
                                        isActive == true ?
                                        cart.addPromotion(promotionList[index]) :
                                        Fluttertoast.showToast(
                                            backgroundColor: Color(0xFFFF0000),
                                            msg: "${AppLocalizations.of(context)?.translate('offer_ended')}");
                                      } else {
                                        cart.addPromotion(promotionList[index]);
                                      }
                                    }
                                    // if(promotionList[index].all_time == '0') {
                                    //   checkOfferTime(promotionList[index]);
                                    //   isActive == true ?
                                    //   cart.addPromotion(promotionList[index]) :
                                    //   Fluttertoast.showToast(
                                    //       backgroundColor: Color(0xFFFF0000),
                                    //       msg: "${AppLocalizations.of(context)?.translate('offer_ended')}");
                                    // }else{
                                    //   cart.addPromotion(promotionList[index]);
                                    // }
                                    Navigator.of(context).pop();
                                  }else{
                                    Fluttertoast.showToast(
                                        backgroundColor: Color(0xFFFF0000),
                                        msg: "${AppLocalizations.of(context)?.translate("empty_cart")}");

                                    Navigator.of(context).pop();
                                  }
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

  checkOfferAmount(Promotion promotion){
    String cartAmount = widget.cartFinalAmount;
    bool hasOutStanding = false;
    if(promotion.type == 1){
      double total = double.parse(cartAmount) - double.parse(promotion.amount!);
      if(total.isNegative){
        return hasOutStanding = true;
      } else {
        return hasOutStanding = false;
      }
    } else {
      return hasOutStanding = false;
    }
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

  checkDate(Promotion promotion){
    DateTime currentDateTime = DateTime.now();
    DateTime parsedStartDate = DateTime.parse(promotion.sdate!);
    DateTime parsedEndDate = DateTime.parse(promotion.edate!);

    //compare date
    int startDateComparison = currentDateTime.compareTo(parsedStartDate);
    int endDateComparison = currentDateTime.compareTo(parsedEndDate);

    if (startDateComparison >= 0 && endDateComparison <= 0) {
      promotionList.add(promotion);
    }
  }

  void readAllPromotion() async {
    List<BranchLinkPromotion> data = await PosDatabase.instance.readBranchLinkPromotion();
    for (int i = 0; i < data.length; i++) {
      List<Promotion> result = await PosDatabase.instance.checkPromotion(data[i].promotion_id!);
      for (int j = 0; j < result.length; j++) {
        if (result[j].auto_apply == '0') {
          if(result[j].all_day != '0'){
            promotionList.add(result[j]);
          } else {
            checkDate(result[j]);
          }
        }
      }
      setState(() {
        _isLoaded = true;
      });
    }
  }
}
