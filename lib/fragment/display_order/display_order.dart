import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/fragment/display_order/view_order_dialog.dart';
import 'package:pos_system/object/dining_option.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier/theme_color.dart';

class DisplayOrderPage extends StatefulWidget {
  const DisplayOrderPage({Key? key}) : super(key: key);

  @override
  _DisplayOrderPageState createState() => _DisplayOrderPageState();
}

class _DisplayOrderPageState extends State<DisplayOrderPage> {
  List<String> list = [];
  String? selectDiningOption = 'All';
  List<OrderCache> orderCacheList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDiningList();
    getOrderList();
  }


  getDiningList() async{
    list.add('All');
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<DiningOption> data = await PosDatabase.instance.readAllDiningOption(userObject['company_id']);
    for(int i=0; i< data.length; i++){
      if(data[i].name != 'Dine in'){
        list.add(data[i].name!);
      }
    }


  }

  getOrderList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final int? branch_id = prefs.getInt('branch_id');
    if (selectDiningOption == 'All') {
      List<OrderCache> data = await PosDatabase.instance.readOrderCacheNoDineIn(
          branch_id.toString(), userObject['company_id']);
      setState(() {
        orderCacheList = data;
      });
    } else {
      List<OrderCache> data = await PosDatabase.instance.readOrderCacheSpecial(
          branch_id.toString(), userObject['company_id'],selectDiningOption!);
      setState(() {
        orderCacheList = data;
      });
    }
  }

  Future<Future<Object?>> openViewOrderDialog(OrderCache data) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: ViewOrderDialogPage(orderCache: data),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: Container(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Order",
                      style: TextStyle(fontSize: 25),
                    ),
                    Spacer(),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 60, 0),
                        child: DropdownButton<String>(
                          onChanged: (String? value) {
                            setState(() {
                              selectDiningOption = value!;
                            });
                            getOrderList();
                          },
                          menuMaxHeight: 300,
                          value: selectDiningOption,
                          // Hide the default underline
                          underline: Container(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: color.backgroundColor,
                          ),
                          isExpanded: true,
                          // The list of options
                          items: list
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        e,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          // Customize the selected item
                          selectedItemBuilder: (BuildContext context) => list
                              .map((e) => Center(
                                    child: Text(e),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: orderCacheList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          child: InkWell(
                            onTap: () {
                              openViewOrderDialog(orderCacheList[index]);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListTile(
                                  leading:
                                      orderCacheList[index].dining_id == '2'
                                          ? Icon(
                                              Icons.fastfood_sharp,
                                              color: color.backgroundColor,
                                              size: 30.0,
                                            )
                                          : Icon(
                                              Icons.delivery_dining,
                                              color: color.backgroundColor,
                                              size: 30.0,
                                            ),
                                  trailing: Text(
                                    '#'+orderCacheList[index].order_cache_id.toString(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  subtitle: Text(
                                    orderCacheList[index].order_by!,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  title: Text(
                                    orderCacheList[index]
                                        .total_amount
                                        .toString(),
                                    style: TextStyle(fontSize: 20),
                                  )),
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
