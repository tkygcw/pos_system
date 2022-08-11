import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/categories.dart';
import 'package:provider/provider.dart';

import '../database/pos_database.dart';
import '../notifier/theme_color.dart';

class EditCategoryDialog extends StatefulWidget {
  final Categories? category;
  final Function() callBack;

  const EditCategoryDialog({Key? key, required this.callBack, this.category})
      : super(key: key);

  @override
  _EditCategoryDialogState createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final myController = TextEditingController();
  bool _submitted = false;
  String categoryColor = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myController.text = widget.category!.name!;
    categoryColor = widget.category!.color!;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    myController.dispose();
  }

  String? get _errorText {
    final text = myController.value.text;
    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    return null;
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_errorText == null) {
      updateCategory();
    }
  }

  changeHexToCode(String hex) {
    hex = hex.toUpperCase().replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF" + hex;
    }
    return int.parse(hex, radix: 16);
  }

  updateCategory() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    Categories categoryData = Categories(
        category_sqlite_id: widget.category!.category_sqlite_id,
        color: categoryColor,
        name: myController.value.text,
        updated_at: dateTime);
    int data = await PosDatabase.instance.updateCategory(categoryData);
    if (data != '') {
      widget.callBack();
      Navigator.of(context).pop(true);
    }
  }

  deleteCategory() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    Categories categoryData = Categories(
      soft_delete: dateTime,
      category_sqlite_id: widget.category!.category_sqlite_id,
    );
    int data = await PosDatabase.instance.deleteCategory(categoryData);
    if (data != '') {
      widget.callBack();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              "Edit Category",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              color: Colors.red,
              onPressed: () async {
                if (await confirm(
                  context,
                  title: const Text('Confirm'),
                  content: const Text('Would you like to remove?'),
                  textOK: const Text('Yes'),
                  textCancel: const Text('No'),
                )) {
                  return deleteCategory();
                }

                // deleteCategory();
              },
            ),
          ],
        ),
        content: Container(
          height: 450.0, // Change as per your requirement
          width: 350.0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                    // Note: pass _controller to the animation argument
                    valueListenable: myController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: TextField(
                          controller: myController,
                          decoration: InputDecoration(
                            errorText: _submitted ? _errorText : null,
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            labelText: 'Category Name',
                          ),
                        ),
                      );
                    }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 0, 10),
                  child: Text(
                    "Category Color",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                MaterialColorPicker(
                  allowShades: false,
                  selectedColor:
                      Color(changeHexToCode(widget.category!.color!)),
                  circleSize: 190,
                  shrinkWrap: true,
                  onMainColorChange: (color) {
                    var hex = '#${color!.value.toRadixString(16).substring(2)}';
                    categoryColor = hex;
                  },
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Submit'),
            onPressed: () {
              _submit();
              // print(selectColor);
            },
          ),
        ],
      );
    });
  }
}
