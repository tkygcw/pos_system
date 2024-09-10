import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
class ReasonInputWidget extends StatefulWidget {
  final Function(String reason) reasonCallBack;
  const ReasonInputWidget({Key? key, required this.reasonCallBack}) : super(key: key);

  @override
  State<ReasonInputWidget> createState() => _ReasonInputWidgetState();
}

class _ReasonInputWidgetState extends State<ReasonInputWidget> {
  @override
  Widget build(BuildContext context) {
    ThemeColor color = context.watch<ThemeColor>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text("Enter reason", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),),
          ),
          TextField(
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: color.backgroundColor),
              ),
            ),
            onChanged: (value) => widget.reasonCallBack(value)
          ),
        ],
      ),
    );
  }
}
