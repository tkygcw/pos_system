import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/controller/controllerObject.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/cart_product.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/utils/Utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/pos_database.dart';
import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_item.dart';
import '../../translation/AppLocalizations.dart';
import '../cart/cart_dialog.dart';

class ProductOrderDialog extends StatefulWidget {
  final Product? productDetail;
  final CartModel cartModel;

  const ProductOrderDialog({Key? key, this.productDetail, required this.cartModel}) : super(key: key);

  @override
  ProductOrderDialogState createState() => ProductOrderDialogState();
}

class ProductOrderDialogState extends State<ProductOrderDialog> {
  ControllerClass streamController = ControllerClass();
  StreamController actionController = StreamController();
  late Stream actionStream;
  late StreamSubscription actionSubscription;
  late CartModel cart;
  Categories? categories;
  String branchLinkProduct_id = '';
  String basePrice = '', finalPrice = '';
  String productStock = '';
  String dialogPrice = '', dialogStock = '';
  num simpleIntInput = 0;
  int pressed = 0;
  String modifierItemPrice = '';
  List<VariantGroup> variantGroup = [];
  List<ModifierGroup> modifierGroup = [];
  List<ModifierItem> checkedModItem = [];
  List<int> preSelectedVariantItemId = [];
  final remarkController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  int checkedModifierLength = 0;
  String newPrice = '';

  bool checkboxValueA = false;
  bool isLoaded = false;
  bool hasPromo = false;
  bool hasStock = false;
  bool isButtonDisabled = false;

  String? initProductName;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    actionStream = actionController.stream.asBroadcastStream();
    productChecking();
    listenAction();
    simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? 0 : 1;
    newPrice = widget.productDetail!.price!;
    quantityController = TextEditingController(text: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? '' : '${simpleIntInput}');
    priceController = TextEditingController(text:  widget.productDetail!.price);
    nameController = TextEditingController(text:  widget.productDetail!.name);
    initProductName = widget.productDetail!.name;
    //getProductPrice(widget.productDetail?.product_id);
  }

  @override
  void dispose() {
    actionSubscription.cancel();
    super.dispose();
    widget.productDetail!.name = initProductName;
  }

  getInitCheckedModItem(){
    for(final group in modifierGroup){
      checkedModItem.addAll(group.modifierChild!.where((child) => child.isChecked == true).toList());
    }
    print("check mod item length: ${checkedModItem.length}");
  }

  productChecking() async {
    print("product allow ticket: ${widget.productDetail?.allow_ticket}");
    print("product ticket count: ${widget.productDetail?.ticket_count}");
    print("product ticket exp: ${widget.productDetail?.ticket_exp}");
    await readProductVariant(widget.productDetail!.product_sqlite_id!);
    await readProductModifier(widget.productDetail!.product_sqlite_id!);
    await getProductPrice(widget.productDetail!.product_sqlite_id);
    await getProductDialogStock(widget.productDetail!);
    categories = await PosDatabase.instance.readSpecificCategoryById(widget.productDetail!.category_sqlite_id!);
    getInitCheckedModItem();
    streamController.productOrderDialogController.sink.add('refresh');
  }

  listenAction(){
    actionSubscription = actionStream.listen((action) async {
      switch(action){
        case 'add-on':{
          await getProductPrice(widget.productDetail!.product_sqlite_id);
          await getProductDialogStock(widget.productDetail!);
          streamController.productOrderDialogController.sink.add('refresh');
        }break;
      }
    });
  }

  Widget variantGroupLayout(VariantGroup variantGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(variantGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < variantGroup.child!.length; i++)
          RadioListTile<int?>(
            value: variantGroup.child![i].variant_item_sqlite_id,
            groupValue: variantGroup.variant_item_sqlite_id,
            onChanged: (ind) async  {
              variantGroup.variant_item_sqlite_id = ind;
              actionController.sink.add("add-on");
            },
            title: Text(variantGroup.child![i].name!),
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  Widget modifierGroupLayout(ModifierGroup modifierGroup, CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(modifierGroup.name!, style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < modifierGroup.modifierChild!.length; i++)
          CheckboxListTile(
            title: Row(
              children: [
                Text('${modifierGroup.modifierChild![i].name!}'),
                Text(
                  ' (+RM ${Utils.convertTo2Dec(modifierGroup.modifierChild![i].price)})',
                  style: TextStyle(fontSize: 12),
                )
              ],
            ),
            value: modifierGroup.modifierChild![i].isChecked,
            onChanged: modifierGroup.modifierChild![i].mod_status! == '2'
                ? null
                : (isChecked) {
              setState(() {
                modifierGroup.modifierChild![i].isChecked = isChecked!;
                addCheckedModItem(modifierGroup.modifierChild![i]);
                actionController.sink.add("add-on");
              });
            },
            controlAffinity: ListTileControlAffinity.trailing,
          )
      ],
    );
  }

  addCheckedModItem(ModifierItem modifierItem){
    if(modifierItem.isChecked == true){
      checkedModItem.add(modifierItem);
    } else {
      checkedModItem.remove(modifierItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        this.cart = cart;
        return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
              return StreamBuilder(
                  stream: streamController.productOrderDialogStream,
                  builder: (context, snapshot) {
                    if(snapshot.hasData){
                      return Center(
                        child: SingleChildScrollView(
                          child: AlertDialog(
                            title: Row(
                              children: [
                                Container(
                                  // constraints: BoxConstraints(maxWidth: 300),
                                  child: Text("${widget.productDetail!.name!}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ?
                                    Text("RM ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.per_quantity_unit!}${widget.productDetail!.unit!}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ))
                                        : Text("RM ${Utils.convertTo2Dec(dialogPrice)} / each",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    Visibility(
                                      visible: dialogStock != '' ? true : false,
                                      child: Text("${AppLocalizations.of(context)!.translate('in_stock')}: ${dialogStock}${widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.unit : ''}",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: dialogStock == '0' ? Colors.red : Colors.black
                                          )),
                                    )

                                  ],
                                )
                              ],
                            ),
                            content: Container(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height > 500 ? 500.0 : MediaQuery.of(context).size.height / 2.5,
                              ),
                              height: MediaQuery.of(context).size.height > 500
                                  ? 500.0
                                  : MediaQuery.of(context).size.height / 2.5, // Change as per your requirement
                              width: MediaQuery.of(context).size.width / 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Visibility(
                                      visible: appSettingModel.show_product_desc!,
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 15.0),
                                        child: Text(widget.productDetail!.description!),
                                      ),
                                    ),
                                    Visibility(
                                      visible: widget.productDetail!.unit == 'each_c' ? true : false,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${AppLocalizations.of(context)!.translate('product_name')}",
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 400,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 273,
                                                  child: TextField(
                                                    autofocus: false,
                                                    controller: nameController,
                                                    keyboardType: TextInputType.text,
                                                    textAlign: TextAlign.center,
                                                    decoration: InputDecoration(
                                                      errorText: getProductNameErrorText(nameController.text),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: color.backgroundColor),
                                                      ),
                                                    ),
                                                    onChanged: (value) => setState(() {
                                                      try{
                                                        widget.productDetail!.name = value;
                                                      }catch (e){
                                                        widget.productDetail!.name = "Custom";
                                                      }
                                                    }),
                                                    onSubmitted: (value) {
                                                      if(widget.productDetail!.name!.isNotEmpty && widget.productDetail!.name!.trim().isNotEmpty) {
                                                        setState(() {
                                                          widget.productDetail!.name = value;
                                                        });
                                                      } else {
                                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_name_empty'));
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${AppLocalizations.of(context)!.translate('price')}",
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 400,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 273,
                                                  child: TextField(
                                                    autofocus: true,
                                                    controller: priceController,
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                    textAlign: TextAlign.center,
                                                    decoration: InputDecoration(
                                                      errorText: getPriceErrorText(priceController.text),
                                                      prefixText: 'RM ',
                                                      focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: color.backgroundColor),
                                                      ),
                                                      hintText: "${Utils.convertTo2Dec(dialogPrice)}",
                                                    ),
                                                    onChanged: (value) async {
                                                      await getProductPrice(widget.productDetail!.product_sqlite_id);
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (value) async {
                                                      await getProductPrice(widget.productDetail!.product_sqlite_id);
                                                      setState(() {});
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (int i = 0; i < variantGroup.length; i++)
                                      variantGroupLayout(variantGroup[i]),
                                    for (int j = 0; j < modifierGroup.length; j++)
                                      Visibility(
                                        visible: modifierGroup[j].modifierChild!.isNotEmpty && modifierGroup[j].dining_id == "" || modifierGroup[j].dining_id == cart.selectedOptionId ? true : false,
                                        child: modifierGroupLayout(modifierGroup[j], cart),
                                      ),
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${AppLocalizations.of(context)!.translate('quantity')}",
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // quantity input
                                        Container(
                                          width: 400,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // quantity input remove button
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: color.backgroundColor,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(Icons.remove, color: Colors.white), // Set the icon color to white.
                                                  onPressed: () {
                                                    if(simpleIntInput >= 1){
                                                      setState(() {
                                                        simpleIntInput -= 1;
                                                        quantityController.text = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                        simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                                      });
                                                    } else{
                                                      setState(() {
                                                        simpleIntInput = 0;
                                                        quantityController.text =  widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                        simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              // quantity input text field
                                              Container(
                                                width: 273,
                                                child: TextField(
                                                  autofocus: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? true : false,
                                                  controller: quantityController,
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                                                      : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                    ),
                                                  ),
                                                  onChanged: (value) {
                                                    if(value != ''){
                                                      setState(() => simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(value.replaceAll(',', '')): int.parse(value.replaceAll(',', '')));
                                                    } else {
                                                      simpleIntInput = 0;
                                                    }
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              // quantity input add button
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: color.backgroundColor,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(Icons.add, color: Colors.white),
                                                  onPressed: () {
                                                    // stock disable or in stock
                                                    if(dialogStock == '' || simpleIntInput+1 < int.parse(dialogStock)) {
                                                      print('stock_quantity: '+dialogStock);
                                                      setState(() {
                                                        simpleIntInput += 1;
                                                        quantityController.text = simpleIntInput.toString();
                                                        simpleIntInput =  int.parse(quantityController.text.replaceAll(',', ''));
                                                      });
                                                    } else{
                                                      print('stock_quantity: '+dialogStock);
                                                      setState(() {
                                                        simpleIntInput = int.parse(dialogStock);
                                                        quantityController.text = simpleIntInput.toString();
                                                        simpleIntInput = int.parse(quantityController.text.replaceAll(',', ''));
                                                      });
                                                      if(dialogStock == '0'){
                                                        print('stock_quantity: '+dialogStock);
                                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.of(context)!.translate('remark'),
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextField(
                                          controller: remarkController,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: color.backgroundColor),
                                            ),
                                          ),
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            actions: <Widget>[
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 4,
                                height: MediaQuery.of(context).size.height / 12,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color.backgroundColor,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.translate('close'),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: isButtonDisabled
                                      ? null
                                      : () {
                                    Navigator.of(context).pop();

                                    // Disable the button after it has been pressed
                                    setState(() {
                                      isButtonDisabled = true;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 4,
                                height: MediaQuery.of(context).size.height / 12,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color.buttonColor,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.translate('add'),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: isButtonDisabled
                                      ? null
                                      : () async {
                                    if(widget.productDetail!.name!.isNotEmpty && widget.productDetail!.name!.trim().isNotEmpty) {
                                      if(priceController.text.isNotEmpty && priceController.text.trim().isNotEmpty) {
                                        await checkProductStock(widget.productDetail!, cart);
                                        //await getBranchLinkProductItem(widget.productDetail!);
                                        if (hasStock) {
                                          if (cart.selectedOption == 'Dine in' && appSettingModel.table_order != 0) {
                                            if(simpleIntInput > 0){
                                              if (cart.selectedTable.isNotEmpty) {
                                                // Disable the button after it has been pressed
                                                setState(() {
                                                  isButtonDisabled = true;
                                                });
                                                await addToCart(cart);
                                                Navigator.of(context).pop();
                                              } else {
                                                openChooseTableDialog(cart, context);
                                              }
                                            } else {
                                              Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('invalid_qty_input'));
                                            }
                                          } else if (cart.selectedOption == 'Dine in' && appSettingModel.table_order != 1) {
                                            // Disable the button after it has been pressed
                                            setState(() {
                                              isButtonDisabled = true;
                                            });
                                            await addToCart(cart);
                                            Navigator.of(context).pop();
                                          } else {
                                            // Disable the button after it has been pressed
                                            setState(() {
                                              isButtonDisabled = true;
                                            });
                                            await addToCart(cart);
                                            Navigator.of(context).pop();
                                          }
                                        } else {
                                          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
                                        }
                                      } else {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_price_empty'));
                                      }
                                    } else {
                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('custom_field_required'));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return CustomProgressBar();
                    }
                  }
              );
            } else {
              ///mobile layout
              return StreamBuilder(
                stream: streamController.productOrderDialogStream,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Center(
                      child: SingleChildScrollView(
                        child: AlertDialog(
                          title: Row(
                            children: [
                              Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
                                child: Text(widget.productDetail!.name!,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                              Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ?
                                  Text("RM ${Utils.convertTo2Dec(dialogPrice)} / ${widget.productDetail!.per_quantity_unit!}${widget.productDetail!.unit!}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )) :
                                  Text("RM ${Utils.convertTo2Dec(dialogPrice)} / each",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Visibility(
                                    visible: dialogStock != '' ? true : false,
                                    child: Text("${AppLocalizations.of(context)!.translate('in_stock')}: ${dialogStock}${widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.unit : ''}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: dialogStock == '0' ? Colors.red : Colors.black
                                        )),
                                  )

                                ],
                              )
                            ],
                          ),
                          content: Container(
                            height: MediaQuery.of(context).size.height /2.5, // Change as per your requirement
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Visibility(
                                    visible: appSettingModel.show_product_desc!,
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 15.0),
                                      child: Text(widget.productDetail!.description!),
                                    ),
                                  ),
                                  Visibility(
                                    visible: widget.productDetail!.unit == 'each_c' ? true : false,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${AppLocalizations.of(context)!.translate('product_name')}",
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 400,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 273,
                                                child: TextField(
                                                  autofocus: false,
                                                  controller: nameController,
                                                  keyboardType: TextInputType.text,
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    errorText: getProductNameErrorText(nameController.text),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                    ),
                                                  ),
                                                  onChanged: (value) => setState(() {
                                                    try{
                                                      widget.productDetail!.name = value;
                                                    }catch (e){
                                                      widget.productDetail!.name = "Custom";
                                                    }
                                                  }),
                                                  onSubmitted: (value) {
                                                    if(widget.productDetail!.name!.isNotEmpty && widget.productDetail!.name!.trim().isNotEmpty) {
                                                      setState(() {
                                                        widget.productDetail!.name = value;
                                                      });
                                                    } else {
                                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_name_empty'));
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${AppLocalizations.of(context)!.translate('price')}",
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 400,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 273,
                                                child: TextField(
                                                  autofocus: true,
                                                  controller: priceController,
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    errorText: getPriceErrorText(priceController.text),
                                                    prefixText: 'RM ',
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                    ),
                                                    hintText: "${Utils.convertTo2Dec(dialogPrice)}",
                                                  ),
                                                  onChanged: (value) async {
                                                    await getProductPrice(widget.productDetail!.product_sqlite_id);
                                                    setState(() {});
                                                  },
                                                  onSubmitted: (value) async {
                                                    await getProductPrice(widget.productDetail!.product_sqlite_id);
                                                    setState(() {});
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (int i = 0; i < variantGroup.length; i++)
                                    variantGroupLayout(variantGroup[i]),
                                  for (int j = 0; j < modifierGroup.length; j++)
                                    Visibility(
                                      visible: modifierGroup[j].modifierChild!.isNotEmpty && modifierGroup[j].dining_id == "" || modifierGroup[j].dining_id == cart.selectedOptionId ? true : false,
                                      child: modifierGroupLayout(modifierGroup[j], cart),
                                    ),
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.translate('quantity'),
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // quantity input
                                      Container(
                                        width: 400,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // quantity input remove button
                                            Container(
                                              decoration: BoxDecoration(
                                                color: color.backgroundColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.remove, color: Colors.white), // Set the icon color to white.
                                                onPressed: () {
                                                  if(simpleIntInput >= 1){
                                                    setState(() {
                                                      simpleIntInput -= 1;
                                                      quantityController.text = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                      simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                                    });
                                                  } else{
                                                    setState(() {
                                                      simpleIntInput = 0;
                                                      quantityController.text =  widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? simpleIntInput.toStringAsFixed(2) : simpleIntInput.toString();
                                                      simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(quantityController.text.replaceAll(',', '')) : int.parse(quantityController.text.replaceAll(',', ''));
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            // quantity input text field
                                            Container(
                                              width: 273,
                                              child: TextField(
                                                autofocus: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? true : false,
                                                controller: quantityController,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                                                    : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  if(value != ''){
                                                    setState(() => simpleIntInput = widget.productDetail!.unit != 'each' && widget.productDetail!.unit != 'each_c' ? double.parse(value.replaceAll(',', '')): int.parse(value.replaceAll(',', '')));
                                                  } else {
                                                    simpleIntInput = 0;
                                                  }
                                                },
                                                onSubmitted: _onSubmitted,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            // quantity input add button
                                            Container(
                                              decoration: BoxDecoration(
                                                color: color.backgroundColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.add, color: Colors.white),
                                                onPressed: () {
                                                  // stock disable or in stock
                                                  if(dialogStock == '' || simpleIntInput+1 < int.parse(dialogStock)) {
                                                    print('stock_quantity: '+dialogStock);
                                                    setState(() {
                                                      simpleIntInput += 1;
                                                      quantityController.text = simpleIntInput.toString();
                                                      simpleIntInput =  int.parse(quantityController.text.replaceAll(',', ''));
                                                    });
                                                  } else{
                                                    print('stock_quantity: '+dialogStock);
                                                    setState(() {
                                                      simpleIntInput = int.parse(dialogStock);
                                                      quantityController.text = simpleIntInput.toString();
                                                      simpleIntInput = int.parse(quantityController.text.replaceAll(',', ''));
                                                    });
                                                    if(dialogStock == '0'){
                                                      print('stock_quantity: '+dialogStock);
                                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 30, 8, 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.translate('remark'),
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextField(
                                        controller: remarkController,
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: color.backgroundColor),
                                          ),
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          actions: <Widget>[
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5,
                              height: MediaQuery.of(context).size.height / 10,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                                onPressed: isButtonDisabled
                                    ? null
                                    : () {
                                  // Disable the button after it has been pressed
                                  setState(() {
                                    isButtonDisabled = true;
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5,
                              height: MediaQuery.of(context).size.height / 10,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color.buttonColor,
                                ),
                                child: Text('${AppLocalizations.of(context)?.translate('add')}'),
                                onPressed: isButtonDisabled
                                    ? null
                                    : () async {
                                  if(widget.productDetail!.name!.isNotEmpty && widget.productDetail!.name!.trim().isNotEmpty) {
                                    if(priceController.text.isNotEmpty && priceController.text.trim().isNotEmpty) {
                                      await checkProductStock(widget.productDetail!, cart);
                                      //await getBranchLinkProductItem(widget.productDetail!);
                                      if (hasStock == true) {
                                        if (cart.selectedOption == 'Dine in' && appSettingModel.table_order != 0) {
                                          if(simpleIntInput > 0){
                                            if (cart.selectedTable.isNotEmpty) {
                                              // Disable the button after it has been pressed
                                              setState(() {
                                                isButtonDisabled = true;
                                              });
                                              await addToCart(cart);
                                              Navigator.of(context).pop();
                                            } else {
                                              openChooseTableDialog(cart, context);
                                            }
                                          } else {
                                            Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('invalid_qty_input'));
                                          }
                                        } else {
                                          // Disable the button after it has been pressed
                                          setState(() {
                                            isButtonDisabled = true;
                                          });
                                          await addToCart(cart);
                                          Navigator.of(context).pop();
                                        }
                                      } else {
                                        Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
                                      }
                                    } else {
                                      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_price_empty'));
                                    }
                                  } else {
                                    Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_name_empty'));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return CustomProgressBar();
                  }
                },
              );
            }
          });
        });

      });
    });
  }

  String? getProductNameErrorText(String textInController){
    if(textInController.isEmpty || textInController.trim().isEmpty){
      return "${AppLocalizations.of(context)?.translate('product_name_empty')}";
    } else {
      return null;
    }
  }

  String? getPriceErrorText(String textInController){
    if(textInController.isEmpty || textInController.trim().isEmpty){
      return "${AppLocalizations.of(context)?.translate('product_price_empty')}";
    } else {
      return null;
    }
  }

  _onSubmitted(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
    await checkProductStock(widget.productDetail!, cart);
    if (hasStock) {
      if (cart.selectedOption == 'Dine in' && localSetting!.table_order != 0) {
        if (simpleIntInput > 0) {
          if (cart.selectedTable.isNotEmpty) {
            // Disable the button after it has been pressed
            setState(() {
              isButtonDisabled = true;
            });
            await addToCart(cart);
            Navigator.of(context).pop();
          } else {
            openChooseTableDialog(cart, context);
          }
        } else {
          Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('invalid_qty_input'));
        }
      } else {
        // Disable the button after it has been pressed
        setState(() {
          isButtonDisabled = true;
        });
        await addToCart(cart);
        Navigator.of(context).pop();
      }
    } else {
      Fluttertoast.showToast(backgroundColor: Color(0xFFFF0000), msg: AppLocalizations.of(context)!.translate('product_variant_sold_out'));
    }
  }

  autoDisableButton(){
    setState(() {
      isButtonDisabled = true;
    });
    Timer(Duration(seconds: 1), () {
      isButtonDisabled = false;
    });
  }

  readProductVariant(int productID) async {
    //loop variant group first
    List<VariantGroup> data = await PosDatabase.instance.readProductVariantGroup(productID);
    for (int i = 0; i < data.length; i++) {
      variantGroup.add(VariantGroup(
          variant_group_sqlite_id: data[i].variant_group_sqlite_id,
          variant_group_id: data[i].variant_group_id,
          child: [],
          name: data[i].name));

      //loop variant child based on variant group id
      List<VariantItem> itemData = await PosDatabase.instance.readProductVariantItem(data[i].variant_group_sqlite_id!);
      List<VariantItem> itemChild = [];
      itemData.sort((a, b) => a.name!.compareTo(b.name!));
      for (int j = 0; j < itemData.length; j++) {
        //pre-check radio button
        if (j == 0) {
          variantGroup[i].variant_item_sqlite_id = itemData[j].variant_item_sqlite_id;
        }
        //store all child into one list
        itemChild.add(VariantItem(
            variant_group_sqlite_id: itemData[j].variant_group_sqlite_id,
            variant_group_id: itemData[j].variant_group_id.toString(),
            name: itemData[j].name,
            variant_item_sqlite_id: itemData[j].variant_item_sqlite_id,
            variant_item_id: itemData[j].variant_item_id));
      }
      //assign list into group child
      variantGroup[i].child = itemChild;
      variantGroup[i].child!.sort((a, b) => a.name!.compareTo(b.name!));
    }
  }

  readProductModifier(int productID, {String? diningOptionId}) async {
    String currentDiningOptionId = diningOptionId ?? widget.cartModel.selectedOptionId;
    List<ModifierGroup> data = await PosDatabase.instance.readProductModifierGroupName(productID);
    if(data.isNotEmpty){
      for (int i = 0; i < data.length; i++) {
        modifierGroup.add(ModifierGroup(
            modifierChild: [],
            name: data[i].name,
            mod_group_id: data[i].mod_group_id,
            dining_id: data[i].dining_id,
            compulsory: data[i].compulsory,
            sequence_number: data[i].sequence_number
        ));
        print("data: ${modifierGroup.length}");
        List<ModifierItem> itemData = await PosDatabase.instance.readProductModifierItem(data[i].mod_group_id!);
        print("mod item data: ${itemData}");
        List<ModifierItem> modItemChild = [];
        if(itemData.isNotEmpty){
          for (int j = 0; j < itemData.length; j++) {
            modItemChild.add(ModifierItem(
                mod_group_id: data[i].mod_group_id.toString(),
                name: itemData[j].name!,
                mod_item_id: itemData[j].mod_item_id,
                mod_status: itemData[j].mod_status,
                isChecked: false));
          }
          if(modifierGroup[i].compulsory == '1' && modifierGroup[i].dining_id == currentDiningOptionId){
            for(int k = 0; k < modItemChild.length; k++){
              modItemChild[k].isChecked = true;
            }
            modifierGroup[i].modifierChild = modItemChild;
          }
          modifierGroup[i].modifierChild = modItemChild;
          await readProductModifierItemPrice(modifierGroup[i]);
        }
      }
      //filter not have mod item mod group
      modifierGroup = modifierGroup.where((item) => item.modifierChild!.isNotEmpty).toList();
      sortModifier();
    }
  }

  sortModifier(){
    modifierGroup.sort((a, b) {
      final aNumber = a.sequence_number!;
      final bNumber = b.sequence_number!;

      bool isANumeric = int.tryParse(aNumber) != null;
      bool isBNumeric = int.tryParse(bNumber) != null;

      if (isANumeric && isBNumeric) {
        return int.parse(aNumber).compareTo(int.parse(bNumber));
      } else if (isANumeric) {
        return -1; // Numeric before alphanumeric
      } else if (isBNumeric) {
        return 1; // Alphanumeric before numeric
      } else {
        // Custom alphanumeric sorting logic
        return compareNatural(aNumber, bNumber);
      }
    });
  }

  readProductModifierItemPrice(ModifierGroup modGroup) async {
    modifierItemPrice = '';

    for (int i = 0; i < modGroup.modifierChild!.length; i++) {
      List<BranchLinkModifier> data = await PosDatabase.instance.readBranchLinkModifier(modGroup.modifierChild![i].mod_item_id.toString());
      modGroup.modifierChild![i].price = data[0].price!;
    }
  }

  getProductPrice(int? productId) async {
    double totalBasePrice = 0.0;
    double totalModPrice = 0.0;
    try {
      List<BranchLinkProduct> data = await PosDatabase.instance.readBranchLinkSpecificProduct(productId.toString());
      List<Product> productData = await PosDatabase.instance.checkSpecificProduct(productId.toString());
      if (data[0].has_variant == '0') {
        if(productData[0].unit == 'each_c') {
          // take new price input
          if(priceController.text == "" || priceController.text.isEmpty) {
            basePrice = "0.00";
          } else {
            basePrice = priceController.text;
          }
        } else {
          // take original base price
          basePrice = data[0].price!;
        }
        finalPrice = basePrice;
        //check product mod group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild!.length; k++) {
            if (group.modifierChild![k].isChecked == true) {
              List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild![k].mod_item_id.toString());
              totalModPrice += double.parse(modPrice[0].price!);
              totalBasePrice = double.parse(basePrice) + totalModPrice;
              finalPrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
        dialogPrice = finalPrice;
      } else {
        List<BranchLinkProduct> productVariant = await PosDatabase.instance.checkProductVariant(await getProductVariant(productId!), productId.toString());
        if(productData[0].unit == 'each_c') {
          if(priceController.text == "" || priceController.text.isEmpty) {
            basePrice = "0.00";
          } else {
            basePrice = priceController.text;
          }
        } else {
          basePrice = productVariant[0].price!;
        }
        finalPrice = basePrice;
        //loop has variant product modifier group
        for (int j = 0; j < modifierGroup.length; j++) {
          ModifierGroup group = modifierGroup[j];
          //loop mod group child
          for (int k = 0; k < group.modifierChild!.length; k++) {
            if (group.modifierChild![k].isChecked == true) {
              List<BranchLinkModifier> modPrice = await PosDatabase.instance.readBranchLinkModifier(group.modifierChild![k].mod_item_id.toString());
              totalModPrice += double.parse(modPrice[0].price!);
              totalBasePrice = double.parse(basePrice) + totalModPrice;
              finalPrice = totalBasePrice.toStringAsFixed(2);
            }
          }
        }
        dialogPrice = finalPrice;
      }
    } catch (e) {
      print('Get product base price error ${e}');
      FLog.error(
        className: "product_order_dialog",
        text: "Get product base price error",
        exception: e,
      );
    }
    return double.parse(finalPrice).toStringAsFixed(2);
  }

  getProductDialogStock(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    if (product.has_variant == 0) {
      List<BranchLinkProduct> data1 = await PosDatabase.instance.readBranchLinkSpecificProduct(product.product_sqlite_id.toString());
      switch(data1[0].stock_type){
        case '1': {
          dialogStock = data1[0].daily_limit.toString();
        }break;
        case '2': {
          dialogStock = data1[0].stock_quantity.toString();
        }break;
        default:{
          dialogStock = '';
        }
      }
    } else {
      //check has variant product stock
      List<BranchLinkProduct> data = await PosDatabase.instance.checkProductVariant(await getProductVariant(product.product_sqlite_id!), product.product_sqlite_id.toString());
      switch(data[0].stock_type){
        case '1': {
          dialogStock = data[0].daily_limit.toString();
        }break;
        case '2': {
          dialogStock = data[0].stock_quantity.toString();
        }break;
        default:{
          dialogStock = '';
        }
      }
    }
  }

  num checkCartProductQuantity(CartModel cart, BranchLinkProduct branchLinkProduct){
    ///get all same item in cart
    List<cartProductItem> sameProductList = cart.cartNotifierItem.where(
            (item) => item.branch_link_product_sqlite_id == branchLinkProduct.branch_link_product_sqlite_id.toString() && item.status == 0
    ).toList();
    if(sameProductList.isNotEmpty){
      /// sum all quantity
      num totalQuantity = sameProductList.fold(0, (sum, product) => sum + product.quantity!);
      return totalQuantity;
    } else {
      return 0;
    }
  }

  checkProductStock(Product product, CartModel cart) async {
    if (product.has_variant == 0) {
      List<BranchLinkProduct> data1 = await PosDatabase.instance.readBranchLinkSpecificProduct(product.product_sqlite_id.toString());
      print("Stock type: ${data1[0].stock_type}");
      switch(data1[0].stock_type){
        case '1' :{
          if (int.parse(data1[0].daily_limit!) > 0 && simpleIntInput <= int.parse(data1[0].daily_limit!)) {
            num stockLeft =  widget.productDetail!.unit == 'each' || widget.productDetail!.unit == 'each_c' ? int.parse(data1[0].daily_limit!) : double.parse(data1[0].daily_limit!) - checkCartProductQuantity(cart, data1[0]);
            bool isQtyNotExceed = simpleIntInput <= stockLeft;
            print('stock left: ${stockLeft}');
            if(stockLeft > 0 && isQtyNotExceed){
              hasStock = true;
            } else {
              hasStock = false;
            }
          } else {
            hasStock = false;
          }
        }break;
        case '2': {
          if (int.parse(data1[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data1[0].stock_quantity!)) {
            num stockLeft =  int.parse(data1[0].stock_quantity!) - checkCartProductQuantity(cart, data1[0]);
            bool isQtyNotExceed = simpleIntInput <= stockLeft;
            if(stockLeft > 0 && isQtyNotExceed){
              hasStock = true;
            } else {
              hasStock = false;
            }
          } else {
            hasStock = false;
          }
        }break;
        default: {
          hasStock = true;
        }
      }
    } else {
      //check has variant product stock
      List<BranchLinkProduct> data = await PosDatabase.instance.checkProductVariant(await getProductVariant(product.product_sqlite_id!), product.product_sqlite_id.toString());
      switch(data[0].stock_type){
        case '1' :{
          if (int.parse(data[0].daily_limit!) > 0 && simpleIntInput <= int.parse(data[0].daily_limit!)) {
            num stockLeft =  int.parse(data[0].daily_limit!) - checkCartProductQuantity(cart, data[0]);
            bool isQtyNotExceed = simpleIntInput <= stockLeft;
            print('stock left: ${stockLeft}');
            if(stockLeft > 0 && isQtyNotExceed){
              hasStock = true;
            } else {
              hasStock = false;
            }
          } else {
            hasStock = false;
          }
        }break;
        case '2': {
          if (int.parse(data[0].stock_quantity!) > 0 && simpleIntInput <= int.parse(data[0].stock_quantity!)) {
            num stockLeft =  int.parse(data[0].stock_quantity!) - checkCartProductQuantity(cart, data[0]);
            bool isQtyNotExceed = simpleIntInput <= stockLeft;
            if(stockLeft > 0 && isQtyNotExceed){
              hasStock = true;
            } else {
              hasStock = false;
            }
          } else {
            hasStock = false;
          }
        }break;
        default: {
          hasStock = true;
        }
      }
    }
    print('has stock ${hasStock}');
  }

  Future<String?> getBranchLinkProductItem(Product product) async {
    branchLinkProduct_id = '';
    try {
      List<BranchLinkProduct> data = await PosDatabase.instance.readBranchLinkSpecificProduct(product.product_sqlite_id.toString());
      if(data.length == 1){
        branchLinkProduct_id = data[0].branch_link_product_sqlite_id.toString();
      } else {
        String productVariant = await getProductVariant(product.product_sqlite_id!);
        BranchLinkProduct? productData = await PosDatabase.instance.readBranchLinkProductByProductVariant(productVariant);
        if(productData != null){
          branchLinkProduct_id = productData.branch_link_product_sqlite_id.toString();
        }
      }
      print("branchLinkProduct_id: ${branchLinkProduct_id}");
      return branchLinkProduct_id;
    } catch (e) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate('make_sure_stock_is_restock'));
      return null;
    }
  }

  getProductVariant(int product_id) async {
    String variant = '';
    String variant2 = '';
    String variant3 = '';
    String productVariant = '';
    try {
      for (int j = 0; j < variantGroup.length; j++) {
        VariantGroup group = variantGroup[j];
        for (int i = 0; i < group.child!.length; i++) {
          if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
            group.child![i].isSelected = true;
            if (variant == '') {
              variant = group.child![i].name!;
              if (variantGroup.length == 1) {
                List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant);
                productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant2 == '') {
              variant2 = variant + " | " + group.child![i].name!;
              if (variantGroup.length == 2) {
                List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant2);
                productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            } else if (variant3 == '') {
              variant3 = variant2 + " | " + group.child![i].name!;
              if (variantGroup.length == 3) {
                List<ProductVariant> data = await PosDatabase.instance.readSpecificProductVariant(product_id.toString(), variant3);
                productVariant = data[0].product_variant_sqlite_id.toString();
                break;
              }
            }
          }
        }
      }
      // print('variant string: ${variant}');
      // print('product variant: ${productVariant}');
      return productVariant;
    } catch (e) {
      print('get product variant error: ${e}');
      FLog.error(
        className: "product_order_dialog",
        text: "get product_id: ${product_id} variant error",
        exception: e,
      );
      return;
    }
  }

  Future<Future<Object?>> openChooseTableDialog(CartModel cartModel, context) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: CartDialog(
                selectedTableList: cartModel.selectedTable,
                callBack: (cart) async {
                  if (cart.selectedTable.isNotEmpty) {
                    // Disable the button after it has been pressed
                    setState(() {
                      isButtonDisabled = true;
                    });
                    await addToCart(cart);
                    Navigator.of(this.context).pop();
                  }
                }
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  compareCartProductModifier({required List<ModifierGroup> cartModifierGroup}){
    List<ModifierItem> checkedCartModItem = [];
    //add all checked modifier item from cart product
    if(cartModifierGroup.isNotEmpty){
      for(int i = 0 ; i < cartModifierGroup.length; i++){
        ModifierGroup group = cartModifierGroup[i];
        for(int j = 0; j < group.modifierChild!.length; j++){
          if(group.modifierChild![j].isChecked == true){
            checkedCartModItem.add(cartModifierGroup[i].modifierChild![j]);
          }
        }
      }
    }
    return checkSame(checkedCartModItem, checkedModItem);
  }

  bool checkSame(List<ModifierItem> checkedCartModItem, List<ModifierItem> checkedModItem) {
    List<int> cartModItemId = [];
    List<int> checkedModItemId = [];
    bool same = true;
    print('cart mod item length:${checkedCartModItem.length}');
    print('checked mod item length:${checkedModItem.length}');
    if (checkedCartModItem.length != checkedModItem.length) {
      same = false;
    } else {
      //insert mod item id into a list
      for(int i = 0; i < checkedCartModItem.length; i++){
        cartModItemId.add(checkedCartModItem[i].mod_item_id!);
      }
      //insert mod item id into a list
      for(int j = 0; j< checkedModItem.length; j++){
        checkedModItemId.add(checkedModItem[j].mod_item_id!);
      }
      //get all same mod item into a list
      List<int> comparedList = cartModItemId.toSet().intersection(checkedModItemId.toSet()).toList();
      print('compared list length: ${comparedList.length}');
      if(comparedList.length == checkedModItem.length){
        same = true;
      } else {
        same = false;
      }
    }
    return same;
  }

  quantityStack({required cartProductItem cartItem, required cartProductItem newAddItem}){
    num value;
    try{
      if(cartItem.unit != 'each' && cartItem.unit != 'each_c'){
        value = num.parse((cartItem.quantity! + newAddItem.quantity!).toStringAsFixed(2));
      } else {
        value = cartItem.quantity! + newAddItem.quantity!;
      }
    }catch(e){
      print("quantity stack error: $e");
      FLog.error(
        className: "product_order_dialog",
        text: "quantity stack error",
        exception: e,
      );
      value = cartItem.quantity! + newAddItem.quantity!;
    }
    return value;
  }

  addToCart(CartModel cart) async {
    //check selected variant
    for (int j = 0; j < variantGroup.length; j++) {
      VariantGroup group = variantGroup[j];
      for (int i = 0; i < group.child!.length; i++) {
        if (group.variant_item_sqlite_id == group.child![i].variant_item_sqlite_id) {
          group.child![i].isSelected = true;
        } else {
          group.child![i].isSelected = false;
        }
      }
    }
    //check checked modifier length
    if(checkedModItem.isNotEmpty){
      checkedModifierLength = checkedModItem.length;
    } else {
      checkedModifierLength = 0;
    }
    var value = cartProductItem(
        branch_link_product_sqlite_id: await getBranchLinkProductItem(widget.productDetail!),
        product_name: widget.productDetail!.name!,
        category_id: widget.productDetail!.category_id!,
        category_name: categories != null ? categories!.name : '',
        price: await getProductPrice(widget.productDetail?.product_sqlite_id),
        quantity: simpleIntInput,
        checkedModifierLength: checkedModifierLength,
        checkedModifierItem: checkedModItem,
        modifier: modifierGroup,
        variant: variantGroup,
        remark: remarkController.text,
        status: 0,
        category_sqlite_id: widget.productDetail!.category_sqlite_id,
        base_price: basePrice,
        refColor: Colors.black,
        unit: widget.productDetail!.unit!,
        per_quantity_unit: widget.productDetail!.unit! != 'each' && widget.productDetail!.unit != 'each_c' ? widget.productDetail!.per_quantity_unit! : '',
        product_sku: widget.productDetail!.SKU!,
        allow_ticket: widget.productDetail?.allow_ticket,
        ticket_count: widget.productDetail?.ticket_count,
        ticket_exp: widget.productDetail?.ticket_exp
    );
    print('value checked item length: ${value.checkedModifierLength}');
    print(jsonEncode((value)));
    //print('value category: ${value.category_name}');
    // print('base price: ${value.base_price}');
    // print('price: ${value.price}');
    List<cartProductItem> item = [];
    if(cart.cartNotifierItem.isEmpty){
      cart.addItem(value);
    } else {
      for(int k = 0; k < cart.cartNotifierItem.length; k++){
        print('cart checked mod item length in cart: ${cart.cartNotifierItem[k].checkedModifierLength}');
        if(cart.cartNotifierItem[k].branch_link_product_sqlite_id == value.branch_link_product_sqlite_id
            && value.remark == cart.cartNotifierItem[k].remark
            && value.product_name == cart.cartNotifierItem[k].product_name
            && value.price == cart.cartNotifierItem[k].price
            && value.checkedModifierLength == cart.cartNotifierItem[k].checkedModifierLength
            && cart.cartNotifierItem[k].status == 0) {
          item.add(cart.cartNotifierItem[k]);
        }
      }
      print('item length: ${item.length}');
      while(item.length > 1){
        for(int i = 0 ; i < item.length; i++){
          bool status = compareCartProductModifier(cartModifierGroup: item[i].modifier!);
          if(status == false){
            item.remove(item[i]);
          }
        }
      }
      print('item after first compare length: ${item.length}');
      if(item.length == 1){
        if(item[0].checkedModifierLength == 0){
          item[0].quantity = quantityStack(cartItem: item[0], newAddItem: value);
        } else {
          bool status = compareCartProductModifier(cartModifierGroup: item[0].modifier!);
          print('compared status: ${status}');
          if(status == false){
            cart.addItem(value);
          } else{
            item[0].quantity = quantityStack(cartItem: item[0], newAddItem: value);
          }
        }
      } else {
        cart.addItem(value);
      }
      print('length after: ${cart.cartNotifierItem.length}');
    }
    cart.resetCount();
  }
}
