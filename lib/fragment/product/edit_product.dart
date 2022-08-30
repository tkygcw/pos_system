import 'dart:convert';
import 'dart:io';
import 'package:checkbox_grouped/checkbox_grouped.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:pos_system/fragment/variant_option.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/pos_database.dart';
import '../../notifier/theme_color.dart';
import '../../object/branch_link_product.dart';
import '../../object/modifier_group.dart';
import '../../object/modifier_link_product.dart';
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
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dailyLimitController = TextEditingController();
  final stockQuantityController = TextEditingController();
  final priceController = TextEditingController();
  final skuController = TextEditingController();
  bool _submitted = false;
  String selectGraphic = "Image";
  List<String> graphicType = ["Image", "Color"];
  String selectStock = "Daily Limit";
  List<String> stockType = ["Daily Limit", "Stock"];
  String selectStatus = "Available Sale";
  List<String> productStatus = ["Available Sale", "Not Available"];
  String selectVariant = "Have Variant";
  List<String> productVariant = ["Have Variant", "No Variant"];
  String? imageDir;
  File? image;
  String productColor = '#ff0000';
  bool skuInUsed = false;
  List<Categories> categoryList = [
    Categories(
        name: 'No Category',
        category_id: 0,
        company_id: '',
        sequence: '',
        color: '',
        created_at: '',
        updated_at: '',
        soft_delete: '')
  ];
  Categories? selectCategory;
  List<ModifierGroup> modifierElement = [];
  List<int> initModifier = [];
  bool isLoading = true;
  GroupController switchController =
  GroupController(isMultipleSelection: true, initSelectedItem: []);
  bool isAdd = false;
  List<Map> variantList = [];
  List<Map> productVariantList = [];

  Future getImage(ImageSource source) async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      final imageTemporary = File(image.path);
      setState(() {
        this.image = imageTemporary;
        this.imageDir = image.path;
      });
    } on PlatformException catch (e) {
      print('failed to pick image: $e');
    }
  }

  Future<File> saveFilePermanently(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final directory = Directory(
        'data/user/0/com.example.pos_system/files/assets/' +
            userObject['company_id']);
    final name = basename(imagePath).replaceAll('image_picker', '');
    final image = File('${directory.path}/$name');
    return File(imagePath).copy(image.path);
  }

  @override
  void initState() {
    // TODO: implement initState
    if (widget.product!.product_id != null) {
      setAllDefaultProduct();
      isAdd = false;
    } else {
      isAdd = true;
      startAdd();
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    dailyLimitController.dispose();
    stockQuantityController.dispose();
    priceController.dispose();
    skuController.dispose();
  }

  String? get errorNameText {
    final text = nameController.value.text;
    if (text.isEmpty) {
      return 'Product name is required';
    }
    return null;
  }

  String? get errorDescriptionText {
    final text = descriptionController.value.text;
    if (text.length > 100) {
      return 'Exceed word limit';
    }
    return null;
  }

  String? get errorDailyLimitText {
    final text = dailyLimitController.value.text;
    if (text.isEmpty) {
      return 'Daily Limit is required';
    }
    return null;
  }

  String? get errorStockQuantityText {
    final text = stockQuantityController.value.text;
    if (text.isEmpty) {
      return 'Stock quantity is required';
    }
    return null;
  }

  String? get errorPriceText {
    final text = priceController.value.text;
    if (text.isEmpty) {
      return 'Price is required';
    }
    if (text == '0' || text == '0.0') {
      return 'Price must larger than 0';
    }
    return null;
  }

  String? get errorSKUText {
    final text = skuController.value.text;
    if (text.isEmpty) {
      return 'SKU is required';
    }
    if (text.length < 4) {
      return 'SKU must more than 4 number';
    }
    return null;
  }

  void _submit(BuildContext context) {
    setState(() => _submitted = true);

    bool productVariantListIsEmpty = false;

    for (int i = 0; i < productVariantList.length; i++) {
      if (productVariantList[i]['quantity'] == '' ||
          productVariantList[i]['price'] == '') {
        productVariantListIsEmpty = true;
        break;
      }
    }
    if (errorNameText == null &&
        errorDescriptionText == null &&
        errorPriceText == null &&
        errorSKUText == null) {
      if (selectStock == 'Daily Limit' && errorDailyLimitText == null) {
        if (selectGraphic == 'Image' && imageDir == null) {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFFC107),
              msg: "Please pick product image");
        } else {
          if (productVariantListIsEmpty && selectVariant == 'Have Variant') {
            Fluttertoast.showToast(
                backgroundColor: Color(0xFFFFC107),
                msg: "Please fill in all the variant list info");
          } else {
            if (selectGraphic == 'Image') {
              saveFilePermanently(imageDir!);
            }
            if (isAdd == true) {
              createProduct();
              Fluttertoast.showToast(
                  backgroundColor: Color(0xff0c1f32),
                  msg: "Create Product Success");
              widget.callBack();
            } else {
              widget.callBack();
            }
            closeDialog(context);
          }
        }
      } else if (selectStock == 'Stock' && errorStockQuantityText == null) {
        if (selectGraphic == 'Image' && imageDir == null) {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFFC107),
              msg: "Please pick product image");
        } else {
          if (productVariantListIsEmpty && selectVariant == 'Have Variant') {
            Fluttertoast.showToast(
                backgroundColor: Color(0xFFFFC107),
                msg: "Please fill in all the variant list info");
          } else {
            if (selectGraphic == 'Image') {
              saveFilePermanently(imageDir!);
            }
            if (isAdd == true) {
              createProduct();
              Fluttertoast.showToast(
                  backgroundColor: Color(0xff0c1f32),
                  msg: "Create Product Success");
              widget.callBack();
            } else {
              widget.callBack();
            }
            closeDialog(context);
          }
        }
      }
    }
  }
  readProductVariantList() async{
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');


  }

  readAllCategories() async {
    List<Categories> data = await PosDatabase.instance.readCategories();
    for (int i = 0; i < data.length; i++) {
      categoryList.add(data[i]);
    }
    selectCategory = categoryList[0];
  }

  setDefaultSKU() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<Product> data =
    await PosDatabase.instance.readDefaultSKU(userObject['company_id']);
    int defaultSKU = int.parse(data[0].SKU!) + 1;
    skuController.text = defaultSKU.toString();
  }

  checKProductSKU() async {
    if (isAdd) {
      List<Product> data =
      await PosDatabase.instance.checkProductSKU(skuController.value.text);
      if (data.length > 0) {
        skuInUsed = true;
      } else {
        skuInUsed = false;
      }
    } else {
      List<Product> data = await PosDatabase.instance
          .checkProductSKUForEdit(skuController.value.text);
      if (data.length > 0) {
        skuInUsed = true;
      } else {
        skuInUsed = false;
      }
    }
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  readVariantGroupAndItem() async {
    List<VariantGroup> group = await PosDatabase.instance
        .readVariantGroup(widget.product!.product_id.toString());
    for (int i = 0; i < group.length; i++) {
      List<String> itemName = [];
      List<VariantItem> item = await PosDatabase.instance
          .readVariantItemForGroup(group[i].variant_group_id.toString());
      for (int j = 0; j < item.length; j++) {
        itemName.add(item[j].name.toString());
      }
      variantList.add({'modGroup': group[i].name, 'modItem': itemName});
    }
  }

  readProductModifier() async {
    List<ModifierGroup> data = await PosDatabase.instance.readAllModifier();
    if (isAdd == false) {
      List<ModifierLinkProduct> productModifier = await PosDatabase.instance
          .readProductModifier(widget.product!.product_id.toString());
      if (productModifier.length > 0) {
        for (int j = 0; j < productModifier.length; j++) {
          initModifier.add(int.parse(productModifier[j].mod_group_id!));
        }
      }
    }
    for (int i = 0; i < data.length; i++) {
      modifierElement.add(data[i]);
    }
    switchController.initSelectedItem = initModifier;
  }

  setAllDefaultProduct() async {
    await readAllCategories();
    await readProductModifier();
    await readVariantGroupAndItem();
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    nameController.text = widget.product!.name!;
    descriptionController.text = widget.product!.description!;
    widget.product!.has_variant == 1 ? selectVariant = 'Have Variant' : selectVariant='No Variant';
    if (widget.product!.stock_type == 1) {
      selectStock = 'Daily Limit';
      dailyLimitController.text = widget.product!.daily_limit!;
    } else {
      selectStock = 'Stock';
      stockQuantityController.text = widget.product!.stock_quantity!;
    }
    priceController.text = widget.product!.price!;
    skuController.text = widget.product!.SKU!;
    for (int i = 0; i < categoryList.length; i++) {
      if (widget.product!.category_id ==
          categoryList[i].category_id.toString()) {
        selectCategory = categoryList[i];
      }
      ;
    }
    if (widget.product!.graphic_type == '1') {
      selectGraphic = 'Color';
      productColor = widget.product!.color!;
    } else {
      selectGraphic = 'Image';
      this.image = File('data/user/0/com.example.pos_system/files/assets/' +
          userObject['company_id'] +
          '/' +
          widget.product!.image!);
    }

    if (widget.product!.available == 1) {
      selectStatus = 'Available Sale';
    } else {
      selectStatus = 'Not Available';
    }
    setState(() {
      isLoading = false;
    });
  }

  createProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    Product productInserted = await PosDatabase.instance.insertProduct(Product(
        product_id: 0,
        category_id: selectCategory!.category_id.toString(),
        company_id: userObject['company_id'],
        name: nameController.value.text,
        price: priceController.value.text,
        description: descriptionController.value.text,
        SKU: skuController.value.text,
        image: imageDir != null
            ? basename(imageDir!).replaceAll('image_picker', '')
            : ' ',
        has_variant: selectVariant == 'Have Variant' ? 1 : 0,
        stock_type: selectStock == 'Daily Limit' ? 1 : 2,
        stock_quantity: stockQuantityController.value.text,
        available: selectStatus == 'Available Sale' ? 1 : 0,
        graphic_type: selectGraphic == 'Image' ? '2' : '1',
        color: productColor,
        daily_limit: dailyLimitController.value.text,
        daily_limit_amount: dailyLimitController.value.text,
        created_at: dateTime,
        updated_at: '',
        soft_delete: ''));

    if (switchController.selectedItem.length != 0) {
      for (int i = 0; i < switchController.selectedItem.length; i++) {
        ModifierLinkProduct data = await PosDatabase.instance
            .insertModifierLinkProduct(ModifierLinkProduct(
            modifier_link_product_id: 0,
            mod_group_id: switchController.selectedItem[i].toString(),
            product_id: productInserted.product_id.toString(),
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
      }
    }

    if (selectVariant == 'Have Variant') {
      for (int i = 0; i < variantList.length; i++) {
        VariantGroup group = await PosDatabase.instance.insertVariantGroup(
            VariantGroup(
                child: [],
                variant_group_id: 0,
                product_id: productInserted.product_id.toString(),
                name: variantList[i]['modGroup'],
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
        for (int j = 0; j < variantList[i]['modItem'].length; j++) {
          VariantItem item = await PosDatabase.instance.insertVariantItem(
              VariantItem(
                  variant_item_id: 0,
                  variant_group_id: group.variant_group_id.toString(),
                  name: variantList[i]['modItem'][j],
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));
        }
      }

      for (int k = 0; k < productVariantList.length; k++) {
        ProductVariant variant = await PosDatabase.instance
            .insertProductVariant(ProductVariant(
            product_variant_id: 0,
            product_id: productInserted.product_id.toString(),
            variant_name: productVariantList[k]['variant_name'],
            SKU: productVariantList[k]['SKU'],
            price: productVariantList[k]['price'],
            stock_type: selectStock == 'Daily Limit' ? '1' : '2',
            daily_limit: selectStock == 'Daily Limit'
                ? productVariantList[k]['quantity']
                : '',
            daily_limit_amount: selectStock == 'Daily Limit'
                ? productVariantList[k]['quantity']
                : '',
            stock_quantity: selectStock != 'Daily Limit'
                ? productVariantList[k]['quantity']
                : '',
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));

        BranchLinkProduct variantBranchProduct = await PosDatabase.instance
            .insertBranchLinkProduct(BranchLinkProduct(
            branch_link_product_id: 0,
            branch_id: branch_id.toString(),
            product_id: productInserted.product_id.toString(),
            has_variant: '1',
            product_variant_id: variant.product_variant_id.toString(),
            b_SKU: branch_id.toString() + variant.SKU.toString(),
            price: variant.price,
            stock_type: selectStock == 'Daily Limit' ? '1' : '2',
            daily_limit:
            selectStock == 'Daily Limit' ? variant.daily_limit : '',
            daily_limit_amount:
            selectStock == 'Daily Limit' ? variant.daily_limit : '',
            stock_quantity:
            selectStock != 'Daily Limit' ? variant.stock_quantity : '',
            created_at: dateTime,
            updated_at: '',
            soft_delete: ''));
        final splitted = productVariantList[k]['variant_name'].split(' | ');

        for (int l = 0; l < splitted.length; l++) {
          VariantItem? item =
          await PosDatabase.instance.readVariantItem(splitted[l]);
          ProductVariantDetail variantdetail = await PosDatabase.instance
              .insertProductVariantDetail(ProductVariantDetail(
              product_variant_detail_id: 0,
              product_variant_id: variant.product_variant_id.toString(),
              variant_item_id: item!.variant_item_id.toString(),
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));
        }
      }
    } else {
      BranchLinkProduct branchProduct = await PosDatabase.instance
          .insertBranchLinkProduct(BranchLinkProduct(
          branch_link_product_id: 0,
          branch_id: branch_id.toString(),
          product_id: productInserted.product_id.toString(),
          has_variant: '0',
          product_variant_id: ' ',
          b_SKU: branch_id.toString() + skuController.value.text,
          price: priceController.value.text,
          stock_type: selectStock == 'Daily Limit' ? '1' : '2',
          daily_limit: dailyLimitController.value.text,
          daily_limit_amount: dailyLimitController.value.text,
          stock_quantity: stockQuantityController.value.text,
          created_at: dateTime,
          updated_at: '',
          soft_delete: ''));
    }
  }

  startAdd() async {
    await readAllCategories();
    await readProductModifier();
    await setDefaultSKU();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading != true
          ? AlertDialog(
        title: Text(
          isAdd ? "Add Product" : "Edit Product",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          height: 450.0, // Change as per your requirement
          width: 480.0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                  // Note: pass _controller to the animation argument
                    valueListenable: nameController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            errorText: _submitted ? errorNameText : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: 'Name',
                          ),
                        ),
                      );
                    }),
                ValueListenableBuilder(
                    valueListenable: descriptionController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: descriptionController,
                          minLines:
                          3, // any number you need (It works as the rows for the textarea)
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                            errorText:
                            _submitted ? errorDescriptionText : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: 'Description(Optional)',
                          ),
                        ),
                      );
                    }),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: DropdownButton<Categories>(
                    onChanged: (Categories? value) {
                      setState(() {
                        selectCategory = value!;
                        print(selectCategory);
                      });
                    },
                    menuMaxHeight: 300,
                    value: selectCategory,
                    // Hide the default underline
                    underline: Container(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: color.backgroundColor,
                    ),
                    isExpanded: true,
                    // The list of options
                    items: categoryList
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e.name!,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ))
                        .toList(),
                    // Customize the selected item
                    selectedItemBuilder: (BuildContext context) =>
                        categoryList
                            .map((e) => Center(
                          child: Text(e.name!),
                        ))
                            .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RadioGroup<String>.builder(
                    direction: Axis.horizontal,
                    groupValue: selectStock,
                    horizontalAlignment: MainAxisAlignment.spaceBetween,
                    onChanged: (value) => setState(() {
                      selectStock = value!;
                    }),
                    items: stockType,
                    textStyle:
                    TextStyle(fontSize: 15, color: color.buttonColor),
                    itemBuilder: (item) => RadioButtonBuilder(
                      item,
                    ),
                    activeColor: color.backgroundColor,
                  ),
                ),
                selectStock == 'Daily Limit'
                    ? ValueListenableBuilder(
                    valueListenable: dailyLimitController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: dailyLimitController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            errorText: _submitted
                                ? errorDailyLimitText
                                : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: 'Daily Limit Amount',
                          ),
                        ),
                      );
                    })
                    : ValueListenableBuilder(
                    valueListenable: stockQuantityController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: stockQuantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            errorText: _submitted
                                ? errorStockQuantityText
                                : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: 'Stock Quantity',
                          ),
                        ),
                      );
                    }),
                ValueListenableBuilder(
                    valueListenable: priceController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          decoration: InputDecoration(
                            errorText: _submitted ? errorPriceText : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: 'Price',
                          ),
                        ),
                      );
                    }),
                ValueListenableBuilder(
                    valueListenable: skuController,
                    builder: (context, TextEditingValue value, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: skuController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            errorText: _submitted ? errorSKUText : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.backgroundColor),
                            ),
                            labelText: 'SKU',
                          ),
                        ),
                      );
                    }),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                      child: Text(
                        'Modifier',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SimpleGroupedCheckbox<int>(
                      controller: switchController,
                      itemsTitle: List.generate(modifierElement.length,
                              (index) => modifierElement[index].name!),
                      values: List.generate(
                          modifierElement.length,
                              (index) =>
                          modifierElement[index].mod_group_id!),
                      groupStyle: GroupStyle(
                        itemTitleStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        activeColor: color.backgroundColor,
                      ),
                      checkFirstElement: false,
                      onItemSelected: (data) {
                        print(data);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RadioGroup<String>.builder(
                    direction: Axis.horizontal,
                    groupValue: selectVariant,
                    horizontalAlignment: MainAxisAlignment.spaceBetween,
                    onChanged: (value) => setState(() {
                      selectVariant = value!;
                    }),
                    items: productVariant,
                    textStyle:
                    TextStyle(fontSize: 15, color: color.buttonColor),
                    itemBuilder: (item) => RadioButtonBuilder(
                      item,
                    ),
                    activeColor: color.backgroundColor,
                  ),
                ),
                selectVariant == 'Have Variant'
                    ? Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: Text(
                        'Variant',
                        style:
                        TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: variantList.length,
                        itemBuilder:
                            (BuildContext context, int index) {
                          return ListTile(
                            title: Text(
                                variantList[index]['modGroup']),
                            subtitle: customText(
                                variantList[index]['modItem']),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  variantList.removeAt(index);
                                  createProductVariantList();
                                });
                              },
                            ),
                          );
                        }),
                    variantList.length < 3
                        ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                          15, 0, 15, 0),
                      child: ElevatedButton(
                        child: Text("Add Variant"),
                        onPressed: () {
                          openVariantOptionDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                            primary: color.backgroundColor,
                            textStyle: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                        : Container(),
                    variantList.length != 0
                        ? Card(
                      elevation: 2,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 500,
                            child: DataTable(
                                columns: <DataColumn>[
                                  DataColumn(
                                    label: Text(
                                      'Product Variant',
                                      style: TextStyle(
                                          fontStyle: FontStyle
                                              .italic),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      selectStock ==
                                          'Daily Limit'
                                          ? 'Daily limit'
                                          : 'Stock',
                                      style: TextStyle(
                                          fontStyle: FontStyle
                                              .italic),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Price',
                                      style: TextStyle(
                                          fontStyle: FontStyle
                                              .italic),
                                    ),
                                  ),
                                ],
                                rows: List<DataRow>.generate(
                                    productVariantList.length,
                                        (int index) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text(
                                            productVariantList[
                                            index]
                                            [
                                            'variant_name'])),
                                        DataCell(
                                          Padding(
                                            padding:
                                            const EdgeInsets
                                                .all(
                                                8.0),
                                            child:
                                            TextField(
                                              keyboardType:
                                              TextInputType
                                                  .number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              controller:
                                              TextEditingController(
                                                  text:
                                                  productVariantList[index]['quantity']),
                                              decoration:
                                              InputDecoration(),
                                              onChanged:
                                                  (value) {
                                                changeValue(
                                                    'quantity',
                                                    value,
                                                    productVariantList[
                                                    index]);
                                              },
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding:
                                            const EdgeInsets
                                                .all(
                                                8.0),
                                            child:
                                            TextField(
                                              keyboardType:
                                              TextInputType
                                                  .number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                              controller:
                                              TextEditingController(
                                                  text:
                                                  productVariantList[index]['price']),
                                              decoration:
                                              InputDecoration(),
                                              onChanged:
                                                  (value) {
                                                changeValue(
                                                    'price',
                                                    value,
                                                    productVariantList[
                                                    index]);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ))),
                          ),
                        ],
                      ),
                    )
                        : Container(),
                  ],
                )
                    : Container(),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RadioGroup<String>.builder(
                    direction: Axis.horizontal,
                    groupValue: selectGraphic,
                    horizontalAlignment: MainAxisAlignment.spaceBetween,
                    onChanged: (value) => setState(() {
                      selectGraphic = value!;
                    }),
                    items: graphicType,
                    textStyle:
                    TextStyle(fontSize: 15, color: color.buttonColor),
                    itemBuilder: (item) => RadioButtonBuilder(
                      item,
                    ),
                    activeColor: color.backgroundColor,
                  ),
                ),
                selectGraphic == 'Image'
                    ? Center(
                  child: Column(
                    children: [
                      image != null
                          ? Image.file(
                        image!,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      )
                          : Container(),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Pick Image from Gallery"),
                          ],
                        ),
                        onPressed: () {
                          getImage(ImageSource.gallery);
                        },
                        style: ElevatedButton.styleFrom(
                            primary: color.backgroundColor,
                            textStyle: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt_outlined),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Pick Image from Camera"),
                          ],
                        ),
                        onPressed: () {
                          getImage(ImageSource.camera);
                        },
                        style: ElevatedButton.styleFrom(
                            primary: color.backgroundColor,
                            textStyle: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
                    : MaterialColorPicker(
                  physics: NeverScrollableScrollPhysics(),
                  allowShades: false,
                  selectedColor: Color(int.parse(
                      productColor.replaceAll('#', '0xff'))),
                  circleSize: 190,
                  shrinkWrap: true,
                  onMainColorChange: (color) {
                    var hex =
                        '#${color!.value.toRadixString(16).substring(2)}';
                    productColor = hex;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RadioGroup<String>.builder(
                    direction: Axis.horizontal,
                    groupValue: selectStatus,
                    horizontalAlignment: MainAxisAlignment.spaceBetween,
                    onChanged: (value) => setState(() {
                      selectStatus = value!;
                    }),
                    items: productStatus,
                    textStyle:
                    TextStyle(fontSize: 15, color: color.buttonColor),
                    itemBuilder: (item) => RadioButtonBuilder(
                      item,
                    ),
                    activeColor: color.backgroundColor,
                  ),
                ),
              ],
            ),
          ),
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
            onPressed: () async {
              await checKProductSKU();
              if (skuInUsed) {
                Fluttertoast.showToast(
                    backgroundColor: Color(0xFFFFC107),
                    msg: "SKU already in used");
              } else {
                _submit(context);
              }
            },
          ),
        ],
      )
          : CustomProgressBar();
    });
  }

  Future<Future<Object?>> openVariantOptionDialog(BuildContext context) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: VariantOptionDialog(
                  callback: (value) => readGroupAndItem(value)),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return null!;
        });
  }

  readGroupAndItem(Map data) {
    variantList.add(data);
    print(variantList);
    createProductVariantList();
  }

  createProductVariantList() {
    productVariantList.clear();
    int num = 0;
    if (variantList.length == 3) {
      for (int i = 0; i < variantList[0]['modItem'].length; i++) {
        for (int j = 0; j < variantList[1]['modItem'].length; j++) {
          for (int k = 0; k < variantList[2]['modItem'].length; k++) {
            productVariantList.add({
              'variant_name': variantList[0]['modItem'][i] +
                  " | " +
                  variantList[1]['modItem'][j] +
                  " | " +
                  variantList[2]['modItem'][k],
              'price': priceController.text,
              'quantity': selectStock == 'Daily Limit'
                  ? dailyLimitController.text
                  : stockQuantityController.text,
              'SKU': skuController.text + (num++).toString()
            });
          }
        }
      }
    } else if (variantList.length == 2) {
      for (int i = 0; i < variantList[0]['modItem'].length; i++) {
        for (int j = 0; j < variantList[1]['modItem'].length; j++) {
          productVariantList.add({
            'variant_name': variantList[0]['modItem'][i] +
                " | " +
                variantList[1]['modItem'][j],
            'price': priceController.text,
            'quantity': selectStock == 'Daily Limit'
                ? dailyLimitController.text
                : stockQuantityController.text,
            'SKU': skuController.text + (num++).toString()
          });
        }
      }
    } else if (variantList.length == 1) {
      for (int i = 0; i < variantList[0]['modItem'].length; i++) {
        productVariantList.add({
          'variant_name': variantList[0]['modItem'][i],
          'price': priceController.text,
          'quantity': selectStock == 'Daily Limit'
              ? dailyLimitController.text
              : stockQuantityController.text,
          'SKU': skuController.text + (num++).toString()
        });
      }
    }

    print(productVariantList);
    print(switchController.selectedItem);
  }

  changeValue(String key, dynamic value, Map data) {
    for (int i = 0; i < productVariantList.length; i++) {
      if (productVariantList[i] == data) {
        productVariantList[i][key] = value;
      }
    }
  }

  Widget customText(List data) {
    String value = '';
    for (int i = 0; i < data.length; i++) {
      if (i < data.length - 1) {
        value += data[i] + ', ';
      } else {
        value += data[i];
      }
    }
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
    );
  }
}
