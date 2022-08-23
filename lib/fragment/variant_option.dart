import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifier/theme_color.dart';

class VariantOptionDialog extends StatefulWidget {
  final Function(Map) callback;
  const VariantOptionDialog({Key? key, required this.callback}) : super(key: key);

  @override
  _VariantOptionDialogState createState() => _VariantOptionDialogState();
}

class _VariantOptionDialogState extends State<VariantOptionDialog> {
  List<String> selected = [];
  TextEditingController modItemController = TextEditingController();
  TextEditingController modGroupNameController = TextEditingController();
  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    modItemController.dispose();
    modGroupNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text("Option"),
        content: Container(
          // Change as per your requirement
          height: 400,
          width: 600.0,
          child: Scaffold(
              backgroundColor: Colors.white,
              body: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: modGroupNameController,
                    decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        labelText: 'Variant Group Name'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: modItemController,
                    focusNode: myFocusNode,
                    onSubmitted: (value) {
                      setState(() {
                        if (!selected.contains(value) && value.isNotEmpty)
                          selected.add(value);
                        modItemController.text = '';
                        print(selected);
                      });
                      myFocusNode.requestFocus();
                    },
                    decoration: InputDecoration(
                        helperText:
                            'Please type the item name and press return or enter on your keyboard',
                        isDense: true,
                        border: OutlineInputBorder(),
                        labelText: 'Variant Item Name'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: selected.length < 1
                        ? null
                        : Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: selected.map((s) {
                              return Chip(
                                  backgroundColor: Colors.blue[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  label: Text(s,
                                      style:
                                          TextStyle(color: Colors.blue[900])),
                                  onDeleted: () {
                                    setState(() {
                                      selected.remove(s);
                                    });
                                  });
                            }).toList()),
                  ),
                ),
                SizedBox(height: 20),
              ])),
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
              addOption();
            },
          ),
        ],
      );
    });
  }

  addOption(){
    Map productVariantList = new Map();

    productVariantList['modGroup'] = modGroupNameController.text;
    productVariantList['modItem'] = selected;

    Navigator.pop(context);
    widget.callback(productVariantList);

  }

}
