import 'dart:async';
import 'dart:convert';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/controller/controllerObject.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/database/pos_firestore.dart';
import 'package:pos_system/object/ingredient_company.dart';
import 'package:pos_system/object/ingredient_company_link_branch.dart';
import 'package:pos_system/object/ingredient_movement.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../page/progress_bar.dart';
import 'package:crypto/crypto.dart';

class EditIngredientDialog extends StatefulWidget {
  final Function() callBack;
  final IngredientCompany? ingredient_company;
  const EditIngredientDialog({required this.callBack, Key? key, this.ingredient_company})
      : super(key: key);

  @override
  _EditIngredientDialogState createState() => _EditIngredientDialogState();
}

class _EditIngredientDialogState extends State<EditIngredientDialog> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  late StreamController streamController;
  late Stream actionStream;
  bool isLoaded = false;
  String ingredientName = '';
  int currentStock = 0, updateStock = 0, dataSelectLimit = 10, calNewStock = 0;
  String? selectedStockAction = 'purchase', stockCalSymbol = '-';
  TextEditingController stockAdjustmentController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  bool isNewSync = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    streamController = controller.editProductController;
    actionStream = actionController.stream.asBroadcastStream();
    currentStock = int.parse(widget.ingredient_company!.stock!);
    getIngredient();
    calculateStock();
    // listenAction();
  }

  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async {
      switch(event){
        case 'init':{
          await getIngredient();
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    final appLocalizations = AppLocalizations.of(context);
    if (appLocalizations != null) {
      remarkController.text = appLocalizations.translate('ingredient_$selectedStockAction' ?? 'ingredient_purchase') ?? 'Error';
    }
  }

  void calculateStock() {
    int stockUpdateValue = int.tryParse(stockAdjustmentController.text) ?? 0;

    if ((selectedStockAction == 'damage' ||
        selectedStockAction == 'lose' ||
        selectedStockAction == 'theft') &&
        stockUpdateValue > currentStock) {
      stockUpdateValue = currentStock;
      stockAdjustmentController.text = stockUpdateValue.toString();
    }

    if (selectedStockAction == 'damage' ||
        selectedStockAction == 'lose' ||
        selectedStockAction == 'theft') {
      calNewStock = currentStock - stockUpdateValue;
      stockCalSymbol = '-';
    } else if (selectedStockAction == 'extra' ||
        selectedStockAction == 'purchase') {
      calNewStock = currentStock + stockUpdateValue;
      stockCalSymbol = '+';
    }
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Row(
          children: [
            Text(
              '$ingredientName',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Spacer(),
          ],
        ),
        content: isLoaded
            ? Container(
          width: 400.0,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  value: selectedStockAction,
                  hint: Text('Select Action'),
                  items: [
                    DropdownMenuItem(value: 'purchase', child: Text(AppLocalizations.of(context)!.translate('ingredient_purchase'))),
                    DropdownMenuItem(value: 'extra', child: Text(AppLocalizations.of(context)!.translate('ingredient_extra'))),
                    DropdownMenuItem(value: 'damage', child: Text(AppLocalizations.of(context)!.translate('ingredient_damage'))),
                    DropdownMenuItem(value: 'lose', child: Text(AppLocalizations.of(context)!.translate('ingredient_lose'))),
                    DropdownMenuItem(value: 'theft', child: Text(AppLocalizations.of(context)!.translate('ingredient_theft'))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStockAction = value;
                      remarkController.text = AppLocalizations.of(context)!.translate('ingredient_$selectedStockAction');
                      calculateStock();
                    });
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: stockAdjustmentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('stock_update_value'),
                    border: OutlineInputBorder(),
                    prefixText: '${stockCalSymbol} ',
                  ),
                  onChanged: (value) {
                    calculateStock();
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: remarkController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('remark'),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "${AppLocalizations.of(context)!.translate('stock_after_adjust')}: $calNewStock ${widget.ingredient_company!.unit}", // Show new stock value
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        )
            : CustomProgressBar(),
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
              if (selectedStockAction != null && stockAdjustmentController.text.isNotEmpty) {
                updateIngredientStock(context, stockAdjustmentController.text);
              }

              Navigator.of(context).pop();
              widget.callBack();
            },
          ),
        ],
      );
    });
  }

  getIngredient() async {
    IngredientCompany? data = await PosDatabase.instance.checkSpecificIngredientCompanyId(widget.ingredient_company!.ingredient_company_id!);
    if(data != null){
      ingredientName = data.name!;
      currentStock = int.parse(data.stock!);
    }
    isLoaded = true;
  }

  updateIngredientStock(BuildContext context, String stockAdjustment) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    PosFirestore posFirestore = PosFirestore.instance;
    isNewSync = prefs.getInt('new_sync') == 1 ? true : false;
    dataSelectLimit = isNewSync ? 1000 : 10;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());

    List<IngredientCompanyLinkBranch> data = await PosDatabase.instance.readIngredientCompanyLinkBranchWithIngredientCompanyId(widget.ingredient_company!.ingredient_company_id!);

    IngredientMovement ingredientMovement = IngredientMovement(
        ingredient_movement_id: 0,
        ingredient_movement_key: '',
        branch_id: branch_id.toString(),
        ingredient_company_link_branch_id: data[0].ingredient_company_link_branch_id.toString(),
        order_cache_key: '',
        order_detail_key: '',
        order_modifier_detail_key: '',
        type: stockCalSymbol == '+' ? 1 : 2,
        movement: '$stockCalSymbol$stockAdjustment',
        source: 0,
        remark: remarkController.text,
        calculate_status: 1,
        sync_status: 0,
        created_at: dateTime,
        updated_at: '',
        soft_delete: ''
    );
    IngredientMovement movementData = await PosDatabase.instance.insertSqliteIngredientMovement(ingredientMovement);
    await insertIngredientMovementKey(movementData, dateTime);

    IngredientCompanyLinkBranch object = IngredientCompanyLinkBranch(
      updated_at: dateTime,
      sync_status: 2,
      stock_quantity: calNewStock.toString(),
      ingredient_company_link_branch_id: data[0].ingredient_company_link_branch_id,
    );
    updateStock = await PosDatabase.instance.updateIngredientCompanyLinkBranchStock(object);
    posFirestore.updateIngredientCompanyLinkBranchStock(object);
  }

  insertIngredientMovementKey(IngredientMovement ingredientMovement, String dateTime) async {
    String key = await generateIngredientMovementKey(ingredientMovement);
    IngredientMovement data = IngredientMovement(
        updated_at: dateTime,
        sync_status: 0,
        ingredient_movement_key: key,
        ingredient_movement_sqlite_id: ingredientMovement.ingredient_movement_sqlite_id
    );
    await PosDatabase.instance.updateIngredientMovementKey(data);
  }

  Future<String> generateIngredientMovementKey(IngredientMovement ingredientMovement) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = ingredientMovement.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + ingredientMovement.ingredient_movement_sqlite_id.toString() + device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
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
