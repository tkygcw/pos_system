import 'package:flutter/material.dart';
import 'package:pos_system/fragment/table/add_table_dialog.dart';
import 'package:pos_system/object/table.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';

class TableMenu extends StatefulWidget {
  const TableMenu({Key? key}) : super(key: key);

  @override
  _TableMenuState createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
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
      return Scaffold(
        body: Container(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(11, 15, 11, 4),
                child: Row(
                  children: [
                    Text(
                      "Table",
                      style: TextStyle(fontSize: 25),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 0, 0),
                      child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              primary: color.backgroundColor),
                          onPressed: () {
                            openAddTableDialog(PosTable());
                          },
                          icon: Icon(Icons.add),
                          label: Text("Table")),
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
              Expanded(
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 5,
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
                                  onLongPress: () {
                                    openAddTableDialog(
                                      tableList[index]
                                    );
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
                // child: GridView.extent(
                //     shrinkWrap: true,
                //     maxCrossAxisExtent: 180.0,
                //     children: [
                //   Container(
                //     child: Card(
                //       child: Stack(
                //         alignment: Alignment.bottomLeft,
                //         children: [
                //           Ink.image(
                //             image: NetworkImage(
                //                 "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png"),
                //             child: InkWell(
                //               splashColor: Colors.blue.withAlpha(30),
                //               onTap: () {},
                //             ),
                //             fit: BoxFit.cover,
                //           ),
                //           Container(
                //               alignment: Alignment.center, child: Text("#1")),
                //           Container(
                //             alignment: Alignment.topCenter, child: Text("RM199.00", style: TextStyle(fontSize: 18),),
                //           )
                //         ],
                //       ),
                //     ),
                //   ),
                //   Container(
                //     child: Card(
                //       child: Stack(
                //         alignment: Alignment.bottomLeft,
                //         children: [
                //           Ink.image(
                //             image: NetworkImage(
                //                 "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png"),
                //             child: InkWell(
                //               splashColor: Colors.blue.withAlpha(30),
                //               onTap: () {},
                //             ),
                //             fit: BoxFit.cover,
                //           ),
                //           Container(
                //               alignment: Alignment.center, child: Text("#2"))
                //         ],
                //       ),
                //     ),
                //   ),
                //   Container(
                //     child: Card(
                //       child: Stack(
                //         alignment: Alignment.bottomLeft,
                //         children: [
                //           Ink.image(
                //             image: NetworkImage(
                //                 "https://www.hometown.in/media/cms/icon/Two-Seater-Dining-Sets.png"),
                //             child: InkWell(
                //               splashColor: Colors.blue.withAlpha(30),
                //               onTap: () {},
                //             ),
                //             fit: BoxFit.cover,
                //           ),
                //           Container(
                //               alignment: Alignment.center, child: Text("#3"))
                //         ],
                //       ),
                //     ),
                //   ),
                //   Container(
                //     child: Card(
                //       child: Stack(
                //         alignment: Alignment.bottomLeft,
                //         children: [
                //           Ink.image(
                //             image: NetworkImage(
                //                 "https://www.hometown.in/media/cms/icon/Four-Seater-Dining-Sets.png"),
                //             child: InkWell(
                //               splashColor: Colors.blue.withAlpha(30),
                //               onTap: () {},
                //             ),
                //             fit: BoxFit.cover,
                //           ),
                //           Container(
                //               alignment: Alignment.center, child: Text("#4"))
                //         ],
                //       ),
                //     ),
                //   ),
                //   Container(
                //     child: Card(
                //       child: Stack(
                //         alignment: Alignment.bottomLeft,
                //         children: [
                //           Ink.image(
                //             image: NetworkImage(
                //                 "https://www.hometown.in/media/cms/icon/Six-Seater-Dining-Sets.png"),
                //             child: InkWell(
                //               splashColor: Colors.blue.withAlpha(30),
                //               onTap: () {},
                //
                //             ),
                //             fit: BoxFit.cover,
                //           ),
                //           Container(
                //               alignment: Alignment.center, child: Text("#5"))
                //         ],
                //       ),
                //     ),
                //   ),
                //   Container(
                //     child: Card(
                //       color: Colors.grey,
                //       child: InkWell(
                //         splashColor: Colors.blue.withAlpha(30),
                //         onTap: () {},
                //         child: Stack(
                //           alignment: Alignment.center,
                //           children: [
                //             Icon(
                //               Icons.add,
                //               color: Colors.white,
                //               size: 30.0,
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   )
                // ])
              )
            ],
          ),
        ),
      );
    });
  }

  Future<Future<Object?>> openAddTableDialog(PosTable posTable) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
                opacity: a1.value,
                child: AddTableDialog(
                  object: posTable,
                  callBack: () {
                    readAllTable();
                  },
                )),
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
