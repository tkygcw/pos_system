import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_modifier_detail.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';


class DetailRemoveDialog extends StatefulWidget {
  final OrderDetail object;
  final Function() callBack;
  const DetailRemoveDialog({Key? key, required this.object, required this.callBack}) : super(key: key);

  @override
  State<DetailRemoveDialog> createState() => _DetailRemoveDialogState();
}

class _DetailRemoveDialogState extends State<DetailRemoveDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
        return AlertDialog(
          title: Text('Confirm remove item ?'),
          content: Container(
            child: Row(
              children: [
                Text(
                    '${widget.object.product_name} ${AppLocalizations.of(context)?.translate('confirm_delete')}')
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: Text('${AppLocalizations.of(context)?.translate('no')}'),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            TextButton(
                child:
                Text('${AppLocalizations.of(context)?.translate('yes')}'),
                onPressed: () {
                  removeOrderDetail();
                  Navigator.of(context).pop();
                })
          ],
        );
    });
  }

  removeOrderDetail() async {
    print('removeOrderDetail called');
    try{
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      int orderCacheData = await PosDatabase.instance.deleteOrderCache(OrderCache(
        soft_delete: dateTime,
        order_cache_id: int.parse(widget.object.order_cache_id!)
      ));

      if(widget.object.modifierItem.isNotEmpty){
        int orderModifierDetailDate = await PosDatabase.instance.deleteOrderModifierDetail(OrderModifierDetail(
            soft_delete: dateTime,
            order_detail_id: widget.object.order_detail_id.toString()
        ));
      }

      int orderDetailData = await PosDatabase.instance.deleteOrderDetail(OrderDetail(
          soft_delete: dateTime,
          order_detail_id: widget.object.order_detail_id
      ));
      widget.callBack();
    }catch(e){
      print('error remove order detail $e');
    }
  }


}
