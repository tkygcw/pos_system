import 'dart:async';
import 'dart:convert';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/controller/controllerObject.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/product.dart';
import '../../page/progress_bar.dart';

class EditProductDialog extends StatefulWidget {
  final Function() callBack;
  final Product? product;
  const EditProductDialog({required this.callBack, Key? key, this.product})
      : super(key: key);

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  late StreamController streamController;
  late Stream actionStream;
  bool isLoaded = false;
  bool productAvailable = false, showInQr = false;
  String productName = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    streamController = controller.editProductController;
    actionStream = actionController.stream.asBroadcastStream();
    getProduct();
    // listenAction();
  }

  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async {
      switch(event){
        case 'init':{
          await getProduct();
          controller.refresh(streamController);
        }
        break;
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              '$productName',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
          ],
        ),
        content: isLoaded ? Container(
          // height: 450.0,
          width: 400.0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('product_for_sale')),
                  subtitle: Text(AppLocalizations.of(context)!.translate('product_for_sale_desc')),
                  trailing: Switch(
                    value: productAvailable,
                    activeColor: color.backgroundColor,
                    onChanged: (value) {
                      setState(() {
                        productAvailable = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('product_show_in_qr')),
                  subtitle: Text(AppLocalizations.of(context)!.translate('product_show_in_qr_desc')),
                  trailing: Switch(
                    value: showInQr,
                    activeColor: color.backgroundColor,
                    onChanged: (value) {
                      setState(() {
                        showInQr = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ) : CustomProgressBar(),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.translate('close')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.translate('save')),
            onPressed: () async {
              updateProductSetting(context);
              Navigator.of(context).pop();
              widget.callBack();
            },
          ),
        ],
      );
    });
  }

  getProduct() async {
    Product? data = await PosDatabase.instance.checkSpecificProductId(widget.product!.product_id!);
    if(data != null){
      productName = data.name!;

      if(data.available == 1){
        productAvailable = true;
      } else {
        productAvailable = false;
      }

      if(data.show_in_qr == 1){
        showInQr = true;
      } else {
        showInQr = false;
      }
    }
    isLoaded = true;
  }

  updateProductSetting(BuildContext context) async {
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    Product object = Product(
        available: productAvailable == true ? 1 : 0,
        show_in_qr: showInQr == true ? 1 : 0,
        sync_status: 2,
        product_id: widget.product!.product_id,
        updated_at: dateTime
    );
    await PosDatabase.instance.updateProductSetting(object);

    List<Product> data = await PosDatabase.instance.readAllNotSyncUpdatedProduct(1000);
    if(data.isNotEmpty){
      final prefs = await SharedPreferences.getInstance();
      final String? branch = prefs.getString('branch');
      Map branchObject = json.decode(branch!);
      for(int i = 0; i < data.length; i++){
        if(branchObject['allow_firestore'] == 1){
          PosFirestore.instance.updateProduct(data[i]);
        }
        _value.add(jsonEncode(data[i]));
      }

      syncProductToCloud(_value.toString(), context);
    }
  }

  syncProductToCloud(String value, BuildContext context) async {
    try{
      bool _hasInternetAccess = await Domain().isHostReachable();
      if (_hasInternetAccess) {
        Map productResponse = await Domain().SyncProductToCloud(value);
        if (productResponse['status'] == '1') {
          List responseJson = productResponse['data'];
          for (int i = 0; i < responseJson.length; i++) {
            await PosDatabase.instance.updateProductSyncStatusFromCloud(responseJson[i]['product_id']);
          }
        } else {
          Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later'));
        }
      }
    } catch(e){
      FLog.error(
        className: "edit_product",
        text: "syncProductToCloud error",
        exception: e,
      );
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('something_went_wrong_please_try_again_later'));
    }
  }
}
