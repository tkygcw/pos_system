import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/object/categories.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/pos_database.dart';
import '../notifier/theme_color.dart';
import '../object/branch_link_product.dart';
import '../object/product.dart';

class AddProductDialog extends StatefulWidget {
  final Function() callBack;
  const AddProductDialog({required this.callBack,Key? key}) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
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
    super.initState();
    readAllCategories();
    setDefaultSKU();
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
    if (selectStock == 'Daily Limit') {
      if (errorNameText == null &&
          errorDescriptionText == null &&
          errorDailyLimitText == null &&
          errorPriceText == null &&
          errorSKUText == null) {
        if (selectGraphic == 'Image' && imageDir == null) {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFFC107),
              msg: "Please pick product image");
        } else {
          if (selectGraphic == 'Image') {
            saveFilePermanently(imageDir!);
          }
          createProduct();
          widget.callBack();
          closeDialog(context);
        }
      }
    } else {
      if (errorNameText == null &&
          errorDescriptionText == null &&
          errorStockQuantityText == null &&
          errorPriceText == null &&
          errorSKUText == null) {
        if (selectGraphic == 'Image' && imageDir == null) {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFFC107),
              msg: "Please pick product image");
        } else {
          if (selectGraphic == 'Image') {
            saveFilePermanently(imageDir!);
          }
          createProduct();
          widget.callBack();
          closeDialog(context);
        }
      }
    }
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

  readAllCategories() async {
    List<Categories> data = await PosDatabase.instance.readCategories();
    for (int i = 0; i < data.length; i++) {
      categoryList.add(data[i]);
    }
    selectCategory = categoryList[0];
  }

  checKProductSKU() async {
    List<Product> data =
        await PosDatabase.instance.checkProductSKU(skuController.value.text);
    if (data.length > 0) {
      skuInUsed = true;
    } else {
      skuInUsed = false;
    }
  }

  createProduct() async {
    final prefs = await SharedPreferences.getInstance();
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
        image: imageDir != null ? basename(imageDir!).replaceAll('image_picker', '') : ' ',
        has_variant: 0,
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
    final int? branch_id = prefs.getInt('branch_id');
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

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return AlertDialog(
        title: Text(
          "Create Product",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          height: 450.0, // Change as per your requirement
          width: 350.0,
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
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
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
                            errorText: _submitted ? errorDescriptionText : null,
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
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
                    selectedItemBuilder: (BuildContext context) => categoryList
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
                      print(selectStock);
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
                                errorText:
                                    _submitted ? errorDailyLimitText : null,
                                border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: color.backgroundColor),
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
                                errorText:
                                    _submitted ? errorStockQuantityText : null,
                                border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: color.backgroundColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: color.backgroundColor),
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
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
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
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.backgroundColor),
                            ),
                            labelText: 'SKU',
                          ),
                        ),
                      );
                    }),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RadioGroup<String>.builder(
                    direction: Axis.horizontal,
                    groupValue: selectGraphic,
                    horizontalAlignment: MainAxisAlignment.spaceBetween,
                    onChanged: (value) => setState(() {
                      selectGraphic = value!;
                      print(selectGraphic);
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
                        selectedColor: Colors.red,
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
                      print(selectStatus);
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
              }
              else{
                _submit(context);

              }
            },
          ),
        ],
      );
    });
  }
}
