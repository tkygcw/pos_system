
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
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
  List<String> list = ['All', 'Take Away', 'Delivery'];
  String? selectDiningOption = 'All';
  List<OrderCache> orderCacheList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getOrderList();
  }

  getOrderList() async{
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final int? branch_id = prefs.getInt('branch_id');
    if(selectDiningOption=='All'){
      List<OrderCache> data = await PosDatabase.instance.readOrderCacheNoDineIn(branch_id.toString(), userObject['company_id']);
      setState(() {
        orderCacheList = data;
      });
    }
    else{

    }
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
                              .map((e) =>
                              DropdownMenuItem(
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
                          selectedItemBuilder: (BuildContext context) =>
                              list
                                  .map((e) =>
                                  Center(
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
                            onTap: (){
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListTile(
                                  leading: Text(orderCacheList[index].dining_id.toString()),
                                  trailing: const Text(
                                    "GFG",
                                    style: TextStyle(color: Colors.green, fontSize: 15),
                                  ),
                                  title: Text(orderCacheList[index].total_amount.toString())
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
      );
    });
  }
}
