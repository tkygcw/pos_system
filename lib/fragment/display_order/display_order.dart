
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';

class DisplayOrderPage extends StatefulWidget {

  const DisplayOrderPage({Key? key}) : super(key: key);

  @override
  _DisplayOrderPageState createState() => _DisplayOrderPageState();
}

class _DisplayOrderPageState extends State<DisplayOrderPage> {
  List<String> list = ['Take Away', 'Delivery'];
  String? selectDiningOption;
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
                )
              ],
            ),
          ),
        ),
      );
    });
  }
}
