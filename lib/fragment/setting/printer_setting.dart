import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';

class PrinterSetting extends StatefulWidget {
  const PrinterSetting({Key? key}) : super(key: key);

  @override
  _PrinterSettingState createState() => _PrinterSettingState();
}

class _PrinterSettingState extends State<PrinterSetting> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (BuildContext context,int index){
                      return ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.grey.shade200,child: Icon(Icons.print, color: Colors.grey,)),
                          title:Text("Printer "+(index+1).toString()),
                        subtitle: Text("Type"),
                        onTap: (){},
                      );
                    }
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FloatingActionButton(
                    backgroundColor: color.backgroundColor,
                    onPressed: () {},
                    tooltip: "Add Printer",
                    child: const Icon(Icons.add),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
