import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/categories.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function() callBack;
  const AddCategoryDialog({required this.callBack, Key? key}) : super(key: key);
  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final myController = TextEditingController();
  String categoryColor = '#ff0000';
  bool _submitted = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
      insertCategory();
    }
  }

  insertCategory() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      Categories data = await PosDatabase.instance.insertCategories(Categories(
        category_id: 0,
        company_id: userObject['company_id'],
        sequence: '',
        updated_at: '',
        soft_delete: '',
        name: myController.value.text,
        color: categoryColor,
        created_at: dateTime,
      ));
      if(data!=''){
        widget.callBack();
        Navigator.of(context).pop(true);
        Fluttertoast.showToast(msg: 'Successfully Insert');
      }
      else{
        Fluttertoast.showToast(msg: 'Fail Insert');
      }
    }catch(error){
      Fluttertoast.showToast(msg: 'Something went wrong. Missing Parameter');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(
          "Create Category",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                        padding: const EdgeInsets.all(8.0),
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
                  selectedColor: Colors.red,
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
            child: const Text('Add'),
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
