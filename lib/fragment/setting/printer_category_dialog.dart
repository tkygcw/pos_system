import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/printer_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../translation/AppLocalizations.dart';

class PrinterCategoryDialog extends StatefulWidget {
  final Function(List<Categories> selectedList) callBack;
  final List<Categories> selectedList;

  const PrinterCategoryDialog(
      {Key? key, required this.callBack, required this.selectedList})
      : super(key: key);

  @override
  State<PrinterCategoryDialog> createState() => _PrinterCategoryDialogState();
}

class _PrinterCategoryDialogState extends State<PrinterCategoryDialog> {
  List<Categories> categoryList = [];
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text('Select category '),
        content: isLoad
            ? Container(
                height: MediaQuery.of(context).size.height / 3,
                width: MediaQuery.of(context).size.width / 3,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < categoryList.length; i++)
                        CheckboxListTile(
                            title: Text('${categoryList[i].name}'),
                            activeColor: color.backgroundColor,
                            value: categoryList[i].isChecked,
                            onChanged: (isChecked) {
                              setState(() {
                                categoryList[i].isChecked = isChecked!;
                              });
                            })
                    ],
                  ),
                ))
            : CustomProgressBar(),
        actions: <Widget>[
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('close')}', style: TextStyle(color: color.buttonColor)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('${AppLocalizations.of(context)?.translate('add')}', style: TextStyle(color: color.backgroundColor)),
            onPressed: () {
              widget.callBack(categoryList);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  readCategory() async {
    List<Categories> data = await PosDatabase.instance.readAllCategory();
    categoryList = List.from(data);
    categoryList.add(Categories(
      category_sqlite_id: 0,
      name: 'other/uncategorized'
    ));

    for (int i = 0; i < categoryList.length; i++) {
      for (int j = 0; j < widget.selectedList.length; j++) {
        if (categoryList[i].category_sqlite_id == widget.selectedList[j].category_sqlite_id) {
          categoryList[i].isChecked = true;
        }
      }
    }

    setState(() {
      isLoad = true;
    });
  }
}
