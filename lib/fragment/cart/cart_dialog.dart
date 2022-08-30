
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/table.dart';
import '../../translation/AppLocalizations.dart';

class CartDialog extends StatefulWidget {
  const CartDialog({Key? key}) : super(key: key);

  @override
  State<CartDialog> createState() => _CartDialogState();
}

class _CartDialogState extends State<CartDialog> {
  List<PosTable> tableList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readAllTable();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text("Select Table"),
        content: Container(
          height: 650,
            width: 650,
            child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      crossAxisSpacing: 5.0,
                      children: List.generate(
                          tableList.length, //this is the total number of cards
                              (index) {
                            // tableList[index].seats == 2;
                            return Card(
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
                                      "RM199.00",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                      : Container()
                                ],
                              ),
                            );
                          }),
                    ),
                  ),
                ],
              ),
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

  readAllTable() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');

    List<PosTable> data =
    await PosDatabase.instance.readAllTable(branch_id!.toInt());

    setState(() {
      tableList = data;
    });
  }
}
