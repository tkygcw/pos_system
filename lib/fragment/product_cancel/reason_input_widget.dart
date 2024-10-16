import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';
class ReasonInputWidget extends StatefulWidget {
  final Function(String reason) reasonCallBack;
  const ReasonInputWidget({Key? key, required this.reasonCallBack}) : super(key: key);

  @override
  State<ReasonInputWidget> createState() => _ReasonInputWidgetState();
}

class _ReasonInputWidgetState extends State<ReasonInputWidget> {
  TextEditingController reasonController = TextEditingController();
  bool doneEdit = false;

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
            child: Text(AppLocalizations.of(context)!.translate('enter_reason'), style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),),
          ),
          TextField(
            controller: reasonController,
            decoration: InputDecoration(
              errorText: doneEdit && reasonController.text == ''?
              AppLocalizations.of(context)!.translate('reason_required') : null,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: color.backgroundColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: color.backgroundColor),
              )
            ),
            onSubmitted: (value){
              setState(() {
                doneEdit = true;
              });
            },
            onChanged: (value) => widget.reasonCallBack(value)
          ),
        ],
      ),
    );
  }
}
