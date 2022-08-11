import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grouped_list/grouped_list.dart';
import '../notifier/theme_color.dart';

List _elements = [
  {'name': 'RM19.00','time':'12:00', 'id':'#1-1000', 'group': '2022-6-1'},
  {'name': 'RM21.90', 'time':'01:00', 'id':'#1-1001', 'group': '2022-6-1'},
  {'name': 'RM32.00', 'time':'02:00', 'id':'#1-1002', 'group': '2022-6-2'},
  {'name': 'RM33.00', 'time':'03:00', 'id':'#1-1003', 'group': '2022-6-2'},
  {'name': 'RM12.50', 'time':'04:00', 'id':'#1-1004', 'group': '2022-6-3'},
  {'name': 'RM11.80', 'time':'05:00', 'id':'#1-1005', 'group': '2022-6-4'},
];

class BillMenu extends StatefulWidget {
  const BillMenu({Key? key}) : super(key: key);

  @override
  _BillMenuState createState() => _BillMenuState();
}

class _BillMenuState extends State<BillMenu> {
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: Container(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                child: Row(
                  children: [
                    Text(
                      "Receipt",
                      style: TextStyle(fontSize: 25),
                    ),
                    SizedBox(width: 500),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          labelText: 'Search',
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.grey, width: 2.0),
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(child: GroupedListView<dynamic,String>(
                shrinkWrap: true,
                elements: _elements,
                groupBy: (element) => element['group'],
                groupComparator: (value1, value2) => value2.compareTo(value1),
                itemComparator: (item1, item2) =>
                    item1['id'].compareTo(item2['id']),
                order: GroupedListOrder.DESC,
                useStickyGroupSeparators: true,
                groupSeparatorBuilder: (String value) => Container(
                  color: Color(0xffFAFAFA),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(380, 10, 380, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: color.backgroundColor,
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: color.iconColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                itemBuilder: (c, element) {
                  return Card(
                    elevation: 4.0,
                    margin:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: SizedBox(
                      child: ListTile(
                        // contentPadding: const EdgeInsets.symmetric(
                        //     horizontal: 20.0, vertical: 10.0),
                        onTap: (){},
                        leading: const Icon(Icons.payments),
                        title: Text(element['name']),
                        subtitle: Text(element['time']),
                        trailing: Text(element['id']),

                      ),
                    ),
                  );
                },
              ))

            ],
          ),
        ),
      );
    });
  }
}
