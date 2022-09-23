import 'package:flutter/cupertino.dart';
import 'package:pos_system/object/order_detail.dart';


class DetailRemoveDialog extends StatefulWidget {
  final OrderDetail? object;
  const DetailRemoveDialog({Key? key, this.object}) : super(key: key);

  @override
  State<DetailRemoveDialog> createState() => _DetailRemoveDialogState();
}

class _DetailRemoveDialogState extends State<DetailRemoveDialog> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
