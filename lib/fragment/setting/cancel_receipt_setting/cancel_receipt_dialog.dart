import 'package:flutter/material.dart';
import 'package:pos_system/fragment/setting/cancel_receipt_setting/mm80_receipt_view.dart';

enum PaperSize {
  mm80,
  mm58
}

class CancelReceiptDialog extends StatefulWidget {
  const CancelReceiptDialog({Key? key}) : super(key: key);

  @override
  State<CancelReceiptDialog> createState() => _CancelReceiptDialogState();
}

class _CancelReceiptDialogState extends State<CancelReceiptDialog> {
  PaperSize receiptView = PaperSize.mm80;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text('Cancel receipt layout'),
          SizedBox(width: 10),
          SegmentedButton(
            style: ButtonStyle(
                side: WidgetStateProperty.all(
                  BorderSide.lerp(BorderSide(
                    style: BorderStyle.solid,
                    color: Colors.blueGrey,
                    width: 1,
                  ),
                      BorderSide(
                        style: BorderStyle.solid,
                        color: Colors.blueGrey,
                        width: 1,
                      ),
                      1),
                )
            ),
            segments: <ButtonSegment<PaperSize>>[
              ButtonSegment(value: PaperSize.mm80, label: Text("80mm")),
              ButtonSegment(value: PaperSize.mm58, label: Text("58mm"))
            ],
            onSelectionChanged: (Set<PaperSize> newSelection) async{
              setState(() {
                receiptView = newSelection.first;
              });
            },
            selected: <PaperSize>{receiptView},
          ),
        ],
      ),
      content: receiptView == PaperSize.mm80 ? mm80ReceiptView(): Container(),
      actions: [
        ElevatedButton(onPressed: (){Navigator.of(context).pop();}, child: Text('close'))
      ],
    );
  }
}
