import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/printer_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/categories.dart';
import '../../translation/AppLocalizations.dart';

class PrinterCategoryDialog extends StatefulWidget {
  const PrinterCategoryDialog({Key? key}) : super(key: key);

  @override
  State<PrinterCategoryDialog> createState() => _PrinterCategoryDialogState();
}

class _PrinterCategoryDialogState extends State<PrinterCategoryDialog> {
  List<Categories> categoryList = [];
  bool isLoad  = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return  Consumer<PrinterModel>(
        builder: (context, PrinterModel printerModel, child) {
          return AlertDialog(
            title: Text('Select category '),
            content: isLoad ?
            Container(
              height: MediaQuery.of(context).size.height / 3,
              width: MediaQuery.of(context).size.width / 3,
              child: Column(
                children: [
                  for (int i = 0; i < categoryList.length; i++)
                  CheckboxListTile(
                    title: Text('${categoryList[i].name}'),
                      value: categoryList[i].isChecked,
                      onChanged: (isChecked) {
                        setState(() {
                          categoryList[i].isChecked = isChecked!;
                        });
                      }
                  )
                ],
              )
            ) : CustomProgressBar(),
            actions: <Widget>[
              TextButton(
                child: Text(
                    '${AppLocalizations.of(context)?.translate('add')}'),
                onPressed: () {
                  for(int i = 0; i < categoryList.length; i++){
                    if(categoryList[i].isChecked){
                      printerModel.addCategories(categoryList[i]);
                    }
                  }
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(
                    '${AppLocalizations.of(context)?.translate('close')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
      );
    });
  }

  readCategory() async {
    List<Categories> data = await PosDatabase.instance.readAllCategory();
    categoryList = List.from(data);
    setState(() {
      isLoad = true;
    });
  }
}
