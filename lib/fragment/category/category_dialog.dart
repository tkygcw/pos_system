import 'dart:convert';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CategoryDialog extends StatefulWidget {
  final Categories? category;
  final Function() callBack;

  const CategoryDialog({Key? key, required this.callBack, this.category})
      : super(key: key);

  @override
  _CategoryDialogState createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final myController = TextEditingController();
  bool _submitted = false;
  String categoryColor = '';
  bool isAdd = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.category!.category_sqlite_id == null) {
      categoryColor = '#ff0000';
      isAdd = true;
    } else {
      isAdd = false;
      myController.text = widget.category!.name!;
      categoryColor = widget.category!.color!;
    }
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
      if (isAdd) {
        insertCategory();
      } else {
        updateCategory();
      }
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
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      int data = await PosDatabase.instance.updateCategory(Categories(
          category_sqlite_id: widget.category!.category_sqlite_id,
          color: categoryColor,
          name: myController.value.text,
          sync_status: 1,
          updated_at: dateTime));
/*
      ------------------------sync to cloud--------------------------------
*/
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        Map response = await Domain().editCategory(categoryColor,
            myController.value.text, widget.category!.category_id.toString());
        if (response['status'] == '1') {
          int syncData =
              await PosDatabase.instance.updateSyncCategory(Categories(
            category_id: widget.category!.category_id,
            sync_status: 2,
            updated_at: dateTime,
            category_sqlite_id: widget.category!.category_sqlite_id,
          ));
        }
      }
/*
      ---------------------------sync end-----------------------------------
*/
      if (data == 1) {
        widget.callBack();
        Navigator.of(context).pop(true);
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_update'));
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('fail_update'));
      }
    } catch (error) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong'));
    }
  }

  deleteCategory() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      int data = await PosDatabase.instance.deleteCategory(Categories(
        soft_delete: dateTime,
        sync_status: 1,
        category_sqlite_id: widget.category!.category_sqlite_id,
      ));
/*
      --------------------sync to cloud-----------------------------
*/
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        Map response = await Domain()
            .deleteCategory(widget.category!.category_id.toString());
        if (response['status'] == '1') {
          int syncData =
              await PosDatabase.instance.updateSyncCategory(Categories(
            category_id: widget.category!.category_id,
            sync_status: 2,
            updated_at: dateTime,
            category_sqlite_id: widget.category!.category_sqlite_id,
          ));
        }
      }
/*
      -------------------sync end--------------------------------------
*/
      if (data == 1) {
        widget.callBack();
        Navigator.of(context).pop(true);
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_delete'));
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('fail_delete'));
      }
    } catch (error) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong'));
    }
  }

  insertCategory() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      Categories data =
          await PosDatabase.instance.insertSyncCategories(Categories(
        category_id: -1,
        company_id: userObject['company_id'],
        sequence: '',
        updated_at: '',
        soft_delete: '',
        name: myController.value.text,
        color: categoryColor,
        sync_status: 0,
        created_at: dateTime,
      ));
/*
      --------------------------sync to cloud--------------------------------
*/
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        Map response = await Domain().insertCategory(
            categoryColor, myController.value.text, userObject['company_id']);
        if (response['status'] == '1') {
          int syncData =
              await PosDatabase.instance.updateSyncCategory(Categories(
            category_id: response['category'],
            sync_status: 2,
            updated_at: dateTime,
            category_sqlite_id: data.category_sqlite_id,
          ));
        }
      }
/*
      -----------------------------sync end----------------------------------
*/
      if (data.category_sqlite_id != '') {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('successfully_add'));
        widget.callBack();
        Navigator.of(context).pop(true);
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('fail_insert'));
      }
    } catch (error) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              isAdd ? "Add Category" : "Edit Category",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            isAdd
                ? Container()
                : IconButton(
                    icon: const Icon(Icons.delete_outlined),
                    color: Colors.red,
                    onPressed: () async {
                      if (await confirm(
                        context,
                        title: Text(AppLocalizations.of(context)!.translate('confirm')),
                        content: Text(AppLocalizations.of(context)!.translate('category_do_you_want_to_delete')),
                        textOK: Text(AppLocalizations.of(context)!.translate('yes')),
                        textCancel: Text(AppLocalizations.of(context)!.translate('no')),
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
                            labelText: AppLocalizations.of(context)!.translate('category_name'),
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
                  selectedColor: isAdd
                      ? Colors.red
                      : Color(changeHexToCode(categoryColor)),
                  circleSize: 190,
                  shrinkWrap: true,
                  onMainColorChange: (color) {
                    categoryColor =
                        '#${color!.value.toRadixString(16).substring(2)}';
                  },
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.translate('close')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.translate('submit')),
            onPressed: () {
              _submit();
            },
          ),
        ],
      );
    });
  }
}
