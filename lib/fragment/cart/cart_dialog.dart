import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/notifier/cart_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/order_cache.dart';
import '../../object/table.dart';
import '../../translation/AppLocalizations.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class CartDialog extends StatefulWidget {
  const CartDialog({Key? key}) : super(key: key);

  @override
  State<CartDialog> createState() => _CartDialogState();
}

class _CartDialogState extends State<CartDialog> {
  List<PosTable> tableList = [];
  late StreamController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = StreamController();
    readAllTable();
  }

  Widget DragItemLayout(int index) {
    return Container(
      width: 140.0,
      height: 140.0,
      child: Card(
        key: ValueKey(tableList[index].table_id),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Ink.image(
              image: tableList[index].seats == '2'
                  ? NetworkImage(
                      "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
                  : tableList[index].seats == '4'
                      ? NetworkImage(
                          "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
                      : tableList[index].seats == '6'
                          ? NetworkImage(
                              "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
                          : NetworkImage(
                              "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
              ),
              fit: BoxFit.cover,
            ),
            Container(
                alignment: Alignment.center,
                child: Text("#" + tableList[index].number!)),
            tableList[index].status == 1
                ? Container(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "${tableList[index].total_Amount.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  Future showSecondDialog(
      BuildContext context, ThemeColor color, int dragIndex, int targetIndex, CartModel cart) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Confirm merge table'),
        content: SizedBox(
            height: 100.0, width: 350.0, child: Text('merge table ${tableList[dragIndex].number} with table ${tableList[targetIndex].number} ?')),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
            onPressed: () {
              if(tableList[dragIndex].table_id != tableList[targetIndex].table_id){
                cart.selectedTable.clear();
                cart.addTable(tableList[targetIndex]);
                cart.addTable(tableList[dragIndex]);
              }else{
                Fluttertoast.showToast(
                    backgroundColor: Color(0xFFFF0000),
                    msg: "${AppLocalizations.of(context)?.translate('merge_error')}");
              }

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) {
            return AlertDialog(
              title: Text("Select Table"),
              content: Container(
                height: 650,
                width: 650,
                child: Consumer<CartModel>(
                    builder: (context, CartModel cart, child) {
                  return Column(
                    children: [
                      Expanded(
                        child: ReorderableGridView.count(

                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          crossAxisCount: 4,
                          children: tableList
                              .asMap()
                              .map((index, posTable) =>
                                  MapEntry(index, tableItem(cart, index)))
                              .values
                              .toList(),
                          onReorder: (int oldIndex, int newIndex) {
                            showSecondDialog(context, color, oldIndex, newIndex, cart);
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                      '${AppLocalizations.of(context)?.translate('close')}'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    });
  }

  Widget tableItem(CartModel cart, index) {
    return Container(
      height: 100,
      key: Key(index.toString()),
      child: Card(
        color: tableList[index].status != 0 ? Colors.red : Colors.white,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Ink.image(
              image: tableList[index].seats == '2'
                  ? NetworkImage(
                      "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png")
                  : tableList[index].seats == '4'
                      ? NetworkImage(
                          "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png")
                      : tableList[index].seats == '6'
                          ? NetworkImage(
                              "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png")
                          : NetworkImage(
                              "https://png.pngtree.com/png-vector/20190820/ourmid/pngtree-no-image-vector-illustration-isolated-png-image_1694547.jpg"),
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  print("table " + tableList[index].number! + " is selected");
                  cart.selectedTable.clear();
                  cart.addTable(tableList[index]);
                  Navigator.of(context).pop();
                },
              ),
              fit: BoxFit.cover,
            ),
            Container(
                alignment: Alignment.center,
                child: Text("#" + tableList[index].number!)),
            tableList[index].status == 1
                ? Container(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "${tableList[index].total_Amount.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  readAllTable() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<PosTable> data =
        await PosDatabase.instance.readAllTable(branch_id!.toInt());

    tableList = data;
    readAllTableAmount();
  }

  readAllTableAmount() async {
    print('readAllTableAmount called');
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    for (int i = 0; i < tableList.length; i++) {
      List<OrderCache> data = await PosDatabase.instance
          .readTableOrderCache(branch_id.toString(), tableList[i].table_id!);

      for (int j = 0; j < data.length; j++) {
        tableList[i].total_Amount += double.parse(data[j].total_amount!);
      }
    }
    controller.add('refresh');
  }
}
