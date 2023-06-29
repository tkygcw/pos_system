import 'dart:convert';
import 'dart:io';
import 'package:checkbox_grouped/checkbox_grouped.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/domain.dart';
import 'package:pos_system/fragment/variant_option.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
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

  String imagePath = '';
  String? companyID = '';

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

  readCompanyID() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    imagePath = prefs.getString('local_path')!;
    Map userObject = json.decode(user!);
    companyID = userObject['company_id'];
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
    if (isAdd) {
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
        if (selectStock == 'Daily Limit' && errorDailyLimitText != null) {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFFC107),
              msg: "Please fill in all the required field");
        } else if (selectStock == 'Stock' && errorStockQuantityText != null) {
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFFC107),
              msg: "Please fill in all the required field");
        } else {
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
              createProduct(context);
            }
          }
        }
      } else {
        Fluttertoast.showToast(
            backgroundColor: Color(0xFFFFC107),
            msg: "Please fill in all the required field");
      }
    } else {
      updateProductAvailability();
      // if (errorNameText == null &&
      //     errorDescriptionText == null &&
      //     errorPriceText == null &&
      //     errorSKUText == null) {
      //   if (selectStock == 'Daily Limit' && errorDailyLimitText != null) {
      //     Fluttertoast.showToast(
      //         backgroundColor: Color(0xFFFFC107),
      //         msg: "Please fill in all the required field");
      //   } else if (selectStock == 'Stock' && errorStockQuantityText != null) {
      //     Fluttertoast.showToast(
      //         backgroundColor: Color(0xFFFFC107),
      //         msg: "Please fill in all the required field");
      //   } else {
      //     if (imageDir == null &&
      //         widget.product!.image == '' &&
      //         selectGraphic == 'Image') {
      //       Fluttertoast.showToast(
      //           backgroundColor: Color(0xFFFFC107),
      //           msg: "Please pick product image");
      //     } else {
      //       if (productVariantListIsEmpty && selectVariant == 'Have Variant') {
      //         Fluttertoast.showToast(
      //             backgroundColor: Color(0xFFFFC107),
      //             msg: "Please fill in all the variant list info");
      //       } else {
      //         updateProduct(context);
      //       }
      //     }
      //   }
      // } else {
      //   Fluttertoast.showToast(
      //       backgroundColor: Color(0xFFFFC107),
      //       msg: "Please fill in all the required field");
      // }
    }
    Navigator.of(context).pop();
  }

  updateProductAvailability() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    Product object = Product(
      product_sqlite_id: widget.product!.product_sqlite_id,
      available: selectStatus == 'Available Sale' ? 1 : 0,
      sync_status: 1,
      updated_at: dateTime
    );
    int status = await PosDatabase.instance.updateProductAvailability(object);
  }

  readProductVariantList() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkProduct> data = await PosDatabase.instance
        .readBranchLinkProduct(
            branch_id.toString(), widget.product!.product_sqlite_id.toString());
    for (int i = 0; i < data.length; i++) {
      productVariantList.add({
        'variant_name': data[i].variant_name,
        'price': data[i].price,
        'quantity': data[i].stock_type == '1'
            ? data[i].daily_limit_amount
            : data[i].stock_quantity,
        'SKU': data[i].b_SKU
      });
    }
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
      List<Product> data = await PosDatabase.instance.checkProductSKUForEdit(
          skuController.value.text, widget.product!.product_sqlite_id!);
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
        .readVariantGroup(widget.product!.product_sqlite_id.toString());
    for (int i = 0; i < group.length; i++) {
      List<String> itemName = [];
      List<VariantItem> item = await PosDatabase.instance
          .readVariantItemForGroup(group[i].variant_group_sqlite_id.toString());
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
          .readProductModifier(widget.product!.product_sqlite_id.toString());
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
    await readCompanyID();
    await readAllCategories();
    await readProductModifier();
    await readVariantGroupAndItem();
    await readProductVariantList();
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    List<BranchLinkProduct> data = [];
    if (widget.product!.has_variant != 1) {
      data = await PosDatabase.instance.readBranchLinkProduct(
          branch_id.toString(), widget.product!.product_sqlite_id.toString());
    }
    nameController.text = widget.product!.name!;
    descriptionController.text = widget.product!.description!;
    widget.product!.has_variant == 1
        ? selectVariant = 'Have Variant'
        : selectVariant = 'No Variant';
    if (widget.product!.stock_type == 1) {
      selectStock = 'Daily Limit';
      dailyLimitController.text = widget.product!.has_variant == 1
          ? widget.product!.daily_limit!
          : data[0].daily_limit!;
    } else {
      selectStock = 'Stock';
      stockQuantityController.text = widget.product!.has_variant == 1
          ? widget.product!.stock_quantity!
          : data[0].stock_quantity!;
    }
    priceController.text = widget.product!.has_variant == 1
        ? widget.product!.price!
        : data[0].price!;
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
      this.image = File(imagePath + '/' + widget.product!.image!);
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

  updateProduct(BuildContext context) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      // if(imageDir != null){
      //   if(widget.product!.image == '' || widget.product!.image == null){
      //     saveFilePermanently(imageDir!);
      //     if (connectivityResult == ConnectivityResult.mobile ||
      //         connectivityResult == ConnectivityResult.wifi) {
      //       storeImage(basename(imageDir!).replaceAll('image_picker', ''));
      //     }
      //   }
      //   else{
      //     deleteFile(widget.product!.image);
      //     saveFilePermanently(imageDir!);
      //     if (connectivityResult == ConnectivityResult.mobile ||
      //         connectivityResult == ConnectivityResult.wifi) {
      //       deleteImage(widget.product!.image!);
      //       storeImage(basename(imageDir!).replaceAll('image_picker', ''));
      //     }
      //
      //   }
      // }
      // else{
      //   if (widget.product!.image != '' || widget.product!.image != null) {
      //     deleteFile(widget.product!.image);
      //     if (connectivityResult == ConnectivityResult.mobile ||
      //         connectivityResult == ConnectivityResult.wifi) {
      //       deleteImage(widget.product!.image!);
      //     }
      //   }
      // }

//       int productUpdated = await PosDatabase.instance.updateProduct(Product(
//         category_sqlite_id: selectCategory!.category_sqlite_id.toString(),
//         category_id: selectCategory!.category_id.toString(),
//         name: nameController.value.text,
//         price: priceController.value.text,
//         description: descriptionController.value.text,
//         SKU: skuController.value.text,
//         image: imageDir != null
//             ? basename(imageDir!).replaceAll('image_picker', '')
//             : widget.product!.image,
//         has_variant: selectVariant == 'Have Variant' ? 1 : 0,
//         stock_type: selectStock == 'Daily Limit' ? 1 : 2,
//         stock_quantity: stockQuantityController.value.text,
//         available: selectStatus == 'Available Sale' ? 1 : 0,
//         graphic_type: selectGraphic == 'Image' ? '2' : '1',
//         color: productColor,
//         daily_limit: dailyLimitController.value.text,
//         daily_limit_amount: dailyLimitController.value.text,
//         sync_status: 1,
//         updated_at: dateTime,
//         product_sqlite_id: widget.product!.product_sqlite_id,
//       ));
// /*
//       -------------------------------sync to cloud-----------------------------
// */
//       if (connectivityResult == ConnectivityResult.mobile ||
//           connectivityResult == ConnectivityResult.wifi) {
//         Map response = await Domain().updateProduct(
//             nameController.value.text,
//             selectCategory!.category_id.toString(),
//             descriptionController.value.text,
//             priceController.value.text,
//             skuController.value.text,
//             selectStatus == 'Available Sale' ? '1' : '0',
//             selectVariant == 'Have Variant' ? '1' : '0',
//             selectStock == 'Daily Limit' ? '1' : '2',
//             dailyLimitController.value.text,
//             stockQuantityController.value.text,
//             selectGraphic == 'Image' ? '2' : '1',
//             productColor,
//             imageDir != null
//                 ? basename(imageDir!).replaceAll('image_picker', '')
//                 : widget.product!.image,
//             widget.product!.product_id.toString());
//         if (response['status'] == '1') {
//           int syncData = await PosDatabase.instance.updateSyncProduct(Product(
//             product_id: widget.product!.product_id,
//             sync_status: 2,
//             updated_at: dateTime,
//             product_sqlite_id: widget.product!.product_sqlite_id,
//           ));
//         }
//       }
/*
      -----------------------------end sync------------------------------------
*/
//       List modGroupIdList = [];
//       List<ModifierLinkProduct> getModifierLinkProductList =
//           await PosDatabase.instance.readModifierLinkProductList(
//               widget.product!.product_sqlite_id.toString());
//       for (int z = 0; z < getModifierLinkProductList.length; z++) {
//         modGroupIdList
//             .add(int.parse(getModifierLinkProductList[z].mod_group_id!));
//       }
//
//       List needInsert = switchController.selectedItem
//           .where((i) => !modGroupIdList.contains(i))
//           .toList();
//       List needDelete = modGroupIdList
//           .where((e) => !switchController.selectedItem.contains(e))
//           .toList();
//
//       if (needInsert.length > 0) {
//         for (int i = 0; i < needInsert.length; i++) {
//           ModifierLinkProduct data = await PosDatabase.instance
//               .insertModifierLinkProduct(ModifierLinkProduct(
//                   modifier_link_product_id: 0,
//                   mod_group_id: needInsert[i].toString(),
//                   product_id: widget.product!.product_id.toString(),
//                   product_sqlite_id:
//                       widget.product!.product_sqlite_id.toString(),
//                   sync_status: 0,
//                   created_at: dateTime,
//                   updated_at: '',
//                   soft_delete: ''));
// /*
//             -----------------------sync to cloud--------------------------------
// */
//           if (connectivityResult == ConnectivityResult.mobile ||
//               connectivityResult == ConnectivityResult.wifi) {
//             Map responseInsertMod = await Domain().insertModifierLinkProduct(
//                 needInsert[i].toString(),
//                 widget.product!.product_id.toString());
//             if (responseInsertMod['status'] == '1') {
//               int syncData = await PosDatabase.instance
//                   .updateSyncModifierLinkProduct(ModifierLinkProduct(
//                 modifier_link_product_id:
//                     responseInsertMod['modifier_link_product_id'],
//                 sync_status: 2,
//                 updated_at: dateTime,
//                 modifier_link_product_sqlite_id:
//                     data.modifier_link_product_sqlite_id,
//               ));
//             }
//           }
// /*
//               ---------------------------end sync-------------------------------
// */
//
//         }
//       }
//       if (needDelete.length > 0) {
//         for (int j = 0; j < needDelete.length; j++) {
//           int deleteModifierLinkProduct = await PosDatabase.instance
//               .deleteModifierLinkProduct(ModifierLinkProduct(
//                   mod_group_id: needDelete[j].toString(),
//                   product_sqlite_id:
//                       widget.product!.product_sqlite_id.toString(),
//                   sync_status: 1,
//                   soft_delete: dateTime));
//
// /*
//     -------------------------sync to cloud-------------------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseDeleteMod = await Domain().deleteModifierLinkProduct(
//                   widget.product!.product_id.toString(), needDelete[j].toString());
//               if (responseDeleteMod['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncModifierLinkProductForUpdate(ModifierLinkProduct(
//                         sync_status: 2,
//                         updated_at: dateTime,
//                         mod_group_id: needDelete[j].toString(),
//                         product_sqlite_id:
//                             widget.product!.product_sqlite_id.toString()));
//               }
//             }
// /*
//         -----------------------------end sync----------------------------------
// */
//         }
//       }

      if (widget.product!.has_variant == 1) {
        // List currentGroupName = [];
        // List editGroupName = [];
        // List<VariantGroup> group = await PosDatabase.instance
        //     .readVariantGroup(widget.product!.product_sqlite_id.toString());
        // for (int i = 0; i < group.length; i++) {
        //   currentGroupName.add(group[i].name);
        // }
        // for (int j = 0; j < variantList.length; j++) {
        //   editGroupName.add(variantList[j]['modGroup']);
        // }
        // List needInsert =
        //     editGroupName.where((e) => !currentGroupName.contains(e)).toList();
        // List needDelete =
        //     currentGroupName.where((e) => !editGroupName.contains(e)).toList();
// /*
//           --------------------insert variant group and item---------------------
// */
//         if (needInsert.length > 0) {
//           for (int k = 0; k < needInsert.length; k++) {
//             VariantGroup variantGroupData = await PosDatabase.instance
//                 .insertVariantGroup(VariantGroup(
//                     child: [],
//                     variant_group_id: 0,
//                     product_id: widget.product!.product_id.toString(),
//                     product_sqlite_id:
//                         widget.product!.product_sqlite_id.toString(),
//                     name: needInsert[k],
//                     sync_status: 0,
//                     created_at: dateTime,
//                     updated_at: '',
//                     soft_delete: ''));
// /*
//             -------------------------start to sync------------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseInsertVariantGroup = await Domain()
//                   .insertVariantGroup(
//                       needInsert[k], widget.product!.product_id.toString());
//               if (responseInsertVariantGroup['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncVariantGroup(VariantGroup(
//                   child: [],
//                   variant_group_id:
//                       responseInsertVariantGroup['variant_group_id'],
//                   sync_status: 2,
//                   updated_at: dateTime,
//                   variant_group_sqlite_id:
//                       variantGroupData.variant_group_sqlite_id,
//                 ));
//               }
//             }
// /*
//             ----------------------------end sync--------------------------------
// */
//
//             for (int l = 0; l < variantList.length; l++) {
//               if (needInsert[k] == variantList[l]['modGroup']) {
//                 for (int m = 0; m < variantList[l]['modItem'].length; m++) {
//                   VariantGroup? variantGroup = await PosDatabase.instance
//                       .readVariantGroupID(
//                           variantGroupData.variant_group_sqlite_id.toString());
//                   VariantItem item = await PosDatabase.instance
//                       .insertVariantItem(VariantItem(
//                           variant_item_id: 0,
//                           variant_group_id:
//                               variantGroup?.variant_group_id.toString(),
//                           variant_group_sqlite_id:
//                               variantGroup?.variant_group_sqlite_id.toString(),
//                           name: variantList[l]['modItem'][m],
//                           sync_status: 0,
//                           created_at: dateTime,
//                           updated_at: '',
//                           soft_delete: ''));
// /*
//                   ----------------------sync to cloud---------------------------
// */
//                   if (connectivityResult == ConnectivityResult.mobile ||
//                       connectivityResult == ConnectivityResult.wifi) {
//                     Map responseInsertVariantItem = await Domain()
//                         .insertVariantItem(variantList[l]['modItem'][m],
//                             variantGroup?.variant_group_id.toString());
//                     if (responseInsertVariantItem['status'] == '1') {
//                       int syncData = await PosDatabase.instance
//                           .updateSyncVariantItem(VariantItem(
//                         variant_item_id:
//                             responseInsertVariantItem['variant_item_id'],
//                         sync_status: 2,
//                         updated_at: dateTime,
//                         variant_item_sqlite_id: item.variant_item_sqlite_id,
//                       ));
//                     }
//                   }
// /*
//                 ---------------------------end sync-----------------------------
// */
//                 }
//               }
//             }
//           }
//         }
// /*
//           -------------delete variant group and item----------------------------
// */
//         if (needDelete.length > 0) {
//           for (int n = 0; n < needDelete.length; n++) {
//             VariantGroup? variantGroupData = await PosDatabase.instance
//                 .readSpecificVariantGroup(needDelete[n],
//                     widget.product!.product_sqlite_id.toString());
//
//             int deleteVariantGroup = await PosDatabase.instance
//                 .deleteVariantGroup(VariantGroup(
//                     child: [],
//                     product_sqlite_id:
//                         widget.product!.product_sqlite_id.toString(),
//                     variant_group_sqlite_id:
//                         variantGroupData!.variant_group_sqlite_id,
//                     soft_delete: dateTime));
// /*
//               --------------------------sync to cloud---------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseDeleteVariantGroup = await Domain()
//                   .deleteVariantGroup(widget.product!.product_id.toString(),
//                       variantGroupData.variant_group_id.toString());
//               if (responseDeleteVariantGroup['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncVariantGroup(VariantGroup(
//                   child: [],
//                   variant_group_id: variantGroupData.variant_group_id,
//                   sync_status: 2,
//                   updated_at: dateTime,
//                   variant_group_sqlite_id:
//                       variantGroupData.variant_group_sqlite_id,
//                 ));
//               }
//             }
// /*
//             ------------------------------end to cloud--------------------------
// */
//             int deleteVariantItem =
//                 await PosDatabase.instance.deleteVariantItem(VariantItem(
//               soft_delete: dateTime,
//               sync_status: 1,
//               variant_group_sqlite_id:
//                   variantGroupData.variant_group_sqlite_id.toString(),
//             ));
//
// /*
//               -----------------------sync to cloud-----------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseDeleteVariantItem = await Domain().deleteVariantItem(
//                   variantGroupData.variant_group_id.toString());
//               if (responseDeleteVariantItem['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncVariantItemForUpdate(VariantItem(
//                   sync_status: 2,
//                   updated_at: dateTime,
//                   variant_group_sqlite_id:
//                       variantGroupData.variant_group_sqlite_id.toString(),
//                 ));
//               }
//             }
// /*
//               --------------------------end to cloud---------------------------
// */
//           }
//         }
        List currentProductVariant = [];
        List editProductVariant = [];
        List<ProductVariant> productVariantData = await PosDatabase.instance
            .readProductVariant(widget.product!.product_sqlite_id.toString());
        for (int o = 0; o < productVariantData.length; o++) {
          currentProductVariant.add(productVariantData[o].variant_name);
        }
        for (int p = 0; p < productVariantList.length; p++) {
          editProductVariant.add(productVariantList[p]['variant_name']);
        }
        List needInsertProductVariant = editProductVariant
            .where((e) => !currentProductVariant.contains(e))
            .toList();
        List needDeleteProductVariant = currentProductVariant
            .where((e) => !editProductVariant.contains(e))
            .toList();

//         if (needDeleteProductVariant.length > 0) {
//           for (int q = 0; q < needDeleteProductVariant.length; q++) {
//             ProductVariant? getProductVariant = await PosDatabase.instance
//                 .readProductVariantForUpdate(needDeleteProductVariant[q],
//                     widget.product!.product_sqlite_id.toString());
//             int deleteProductVariant = await PosDatabase.instance
//                 .deleteProductVariant(ProductVariant(
//                     soft_delete: dateTime,
//                     sync_status: 1,
//                     product_sqlite_id:
//                         widget.product!.product_sqlite_id.toString(),
//                     product_variant_sqlite_id:
//                         getProductVariant!.product_variant_sqlite_id));
// /*
//             -------------------------sync to cloud------------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseDeleteProductVariant = await Domain()
//                   .deleteProductVariant(widget.product!.product_id.toString(),
//                       getProductVariant!.product_variant_id.toString());
//               if (responseDeleteProductVariant['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncProductVariantForUpdate(ProductVariant(
//                         sync_status: 2,
//                         updated_at: dateTime,
//                         product_sqlite_id:
//                             widget.product!.product_sqlite_id.toString(),
//                         product_variant_sqlite_id:
//                             getProductVariant!.product_variant_sqlite_id));
//               }
//             }
// /*
//             -----------------------------end sync-------------------------------
// */
//             int deleteProductVariantDetail = await PosDatabase.instance
//                 .deleteProductVariantDetail(ProductVariantDetail(
//                     sync_status: 1,
//                     soft_delete: dateTime,
//                     product_variant_sqlite_id: getProductVariant
//                         .product_variant_sqlite_id
//                         .toString()));
//
// /*
//             ------------------------sync to cloud------------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseDeleteProductVariantDetail =
//                   await Domain() // do until here
//                       .deleteProductVariantDetail(
//                           getProductVariant.product_variant_id.toString());
//               if (responseDeleteProductVariantDetail['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncProductVariantDetailForUpdate(
//                         ProductVariantDetail(
//                             sync_status: 2,
//                             updated_at: dateTime,
//                             product_variant_sqlite_id: getProductVariant!
//                                 .product_variant_sqlite_id
//                                 .toString()));
//               }
//             }
// /*
//             ---------------------------end sync-------------------------------
// */
//             int deleteBranchLinkPorduct = await PosDatabase.instance
//                 .deleteBranchLinkProduct(BranchLinkProduct(
//                     soft_delete: dateTime,
//                     sync_status: 1,
//                     product_sqlite_id:
//                         widget.product!.product_sqlite_id.toString(),
//                     product_variant_sqlite_id: getProductVariant
//                         .product_variant_sqlite_id
//                         .toString()));
// /*
//             -----------------------sync to cloud-------------------------------
// */
//             if (connectivityResult == ConnectivityResult.mobile ||
//                 connectivityResult == ConnectivityResult.wifi) {
//               Map responseDeleteBranchLinkProduct = await Domain()
//                   .deleteBranchLinkProduct(
//                       branch_id.toString(),
//                       widget.product!.product_id.toString(),
//                       getProductVariant.product_variant_id.toString());
//               if (responseDeleteBranchLinkProduct['status'] == '1') {
//                 int syncData = await PosDatabase.instance
//                     .updateSyncBranchLinkProductForUpdate(BranchLinkProduct(
//                         sync_status: 2,
//                         updated_at: dateTime,
//                         product_sqlite_id:
//                             widget.product!.product_sqlite_id.toString(),
//                         product_variant_sqlite_id: getProductVariant!
//                             .product_variant_sqlite_id
//                             .toString()));
//               }
//             }
// /*
//             -------------------------end sync-----------------------------------
// */
//
//           }
//         }
//         if (needInsertProductVariant.length > 0) {
//           for (int r = 0; r < needInsertProductVariant.length; r++) {
//             for (int s = 0; s < productVariantList.length; s++) {
//               if (needInsertProductVariant[r] ==
//                   productVariantList[s]['variant_name']) {
//                 ProductVariant variant = await PosDatabase.instance
//                     .insertProductVariant(ProductVariant(
//                         product_variant_id: 0,
//                         product_sqlite_id:
//                             widget.product!.product_sqlite_id.toString(),
//                         product_id: widget.product!.product_id.toString(),
//                         variant_name: productVariantList[s]['variant_name'],
//                         SKU: productVariantList[s]['SKU'],
//                         price: productVariantList[s]['price'],
//                         stock_type: selectStock == 'Daily Limit' ? '1' : '2',
//                         daily_limit: selectStock == 'Daily Limit'
//                             ? productVariantList[s]['quantity']
//                             : '',
//                         daily_limit_amount: selectStock == 'Daily Limit'
//                             ? productVariantList[s]['quantity']
//                             : '',
//                         stock_quantity: selectStock != 'Daily Limit'
//                             ? productVariantList[s]['quantity']
//                             : '',
//                         sync_status: 0,
//                         created_at: dateTime,
//                         updated_at: '',
//                         soft_delete: ''));
// /*
//                 -------------------------sync to cloud--------------------------
// */
//                 if (connectivityResult == ConnectivityResult.mobile ||
//                     connectivityResult == ConnectivityResult.wifi) {
//                   Map responseInsertProductVariant = await Domain()
//                       .insertProductVariant(
//                           widget.product!.product_id.toString(),
//                           productVariantList[s]['variant_name'],
//                           productVariantList[s]['SKU'],
//                           productVariantList[s]['price'],
//                           selectStock == 'Daily Limit' ? '1' : '2',
//                           productVariantList[s]['quantity']);
//
//                   if (responseInsertProductVariant['status'] == '1') {
//                     int syncData = await PosDatabase.instance
//                         .updateSyncProductVariant(ProductVariant(
//                             product_variant_id: responseInsertProductVariant[
//                                 'product_variant_id'],
//                             sync_status: 2,
//                             updated_at: dateTime,
//                             product_sqlite_id:
//                                 widget.product!.product_sqlite_id.toString(),
//                             product_variant_sqlite_id:
//                                 variant.product_variant_sqlite_id));
//                   }
//                 }
// /*
//                 ---------------------------end sync-----------------------------
// */
//                 ProductVariant? productVariant = await PosDatabase.instance
//                     .readProductVariantID(
//                         variant.product_variant_sqlite_id.toString());
//                 BranchLinkProduct variantBranchProduct = await PosDatabase
//                     .instance
//                     .insertBranchLinkProduct(BranchLinkProduct(
//                         branch_link_product_id: 0,
//                         branch_id: branch_id.toString(),
//                         product_sqlite_id:
//                             widget.product!.product_sqlite_id.toString(),
//                         product_id: widget.product!.product_id.toString(),
//                         has_variant: '1',
//                         product_variant_sqlite_id:
//                             variant.product_variant_sqlite_id.toString(),
//                         product_variant_id:
//                             productVariant!.product_variant_id.toString(),
//                         b_SKU: branch_id.toString() + variant.SKU.toString(),
//                         price: variant.price,
//                         stock_type: selectStock == 'Daily Limit' ? '1' : '2',
//                         daily_limit: selectStock == 'Daily Limit'
//                             ? variant.daily_limit
//                             : '',
//                         daily_limit_amount: selectStock == 'Daily Limit'
//                             ? variant.daily_limit
//                             : '',
//                         stock_quantity: selectStock != 'Daily Limit'
//                             ? variant.stock_quantity
//                             : '',
//                         sync_status: 0,
//                         created_at: dateTime,
//                         updated_at: '',
//                         soft_delete: ''));
// /*
//                 ------------------sync to cloud---------------------------------
// */
//                 if (connectivityResult == ConnectivityResult.mobile ||
//                     connectivityResult == ConnectivityResult.wifi) {
//                   Map responseInsertBranchLinkProduct = await Domain()
//                       .insertBranchLinkProduct(
//                           branch_id.toString(),
//                           widget.product!.product_id.toString(),
//                           '1',
//                           productVariant.product_variant_id.toString(),
//                           branch_id.toString() + variant.SKU.toString(),
//                           variant.price,
//                           selectStock == 'Daily Limit' ? '1' : '2',
//                           selectStock == 'Daily Limit'
//                               ? variant.daily_limit
//                               : variant.stock_quantity);
//                   if (responseInsertBranchLinkProduct['status'] == '1') {
//                     int syncData = await PosDatabase.instance
//                         .updateSyncBranchLinkProduct(BranchLinkProduct(
//                             branch_link_product_id:
//                                 responseInsertBranchLinkProduct[
//                                     'branch_link_product_id'],
//                             sync_status: 2,
//                             updated_at: dateTime,
//                             product_sqlite_id:
//                                 widget.product!.product_sqlite_id.toString(),
//                             product_variant_sqlite_id:
//                                 variant.product_variant_sqlite_id.toString()));
//                   }
//                 }
// /*
//                 ----------------------end sync----------------------------------
// */
//
//                 final splitted =
//                     productVariantList[s]['variant_name'].split(' | ');
//                 for (int l = 0; l < splitted.length; l++) {
//                   VariantItem? item =
//                       await PosDatabase.instance.readVariantItem(splitted[l]);
//                   ProductVariantDetail variantdetail = await PosDatabase
//                       .instance
//                       .insertProductVariantDetail(ProductVariantDetail(
//                           product_variant_detail_id: 0,
//                           product_variant_id:
//                               productVariant!.product_variant_id.toString(),
//                           product_variant_sqlite_id:
//                               variant.product_variant_sqlite_id.toString(),
//                           variant_item_sqlite_id:
//                               item!.variant_item_sqlite_id.toString(),
//                           variant_item_id: item!.variant_item_id.toString(),
//                           sync_status: 0,
//                           created_at: dateTime,
//                           updated_at: '',
//                           soft_delete: ''));
// /*
//                   ----------------------sync to cloud--------------------------
// */
//                   if (connectivityResult == ConnectivityResult.mobile ||
//                       connectivityResult == ConnectivityResult.wifi) {
//                     Map responseInsertProductVariantDetail = await Domain()
//                         .insertProductVariantDetail(
//                             productVariant.product_variant_id.toString(),
//                             item!.variant_item_id.toString());
//                     if (responseInsertProductVariantDetail['status'] == '1') {
//                       int syncData = await PosDatabase.instance
//                           .updateSyncProductVariantDetail(ProductVariantDetail(
//                               product_variant_detail_id:
//                                   responseInsertProductVariantDetail[
//                                       'product_detail_id'],
//                               sync_status: 2,
//                               updated_at: dateTime,
//                               product_variant_sqlite_id:
//                                   variant.product_variant_sqlite_id.toString(),
//                               variant_item_sqlite_id:
//                                   item!.variant_item_sqlite_id.toString()));
//                     }
//                   }
// /*
//                   ----------------------end sync--------------------------------
// */
//                 }
//               }
//             }
//           }
//         }
        if (needInsertProductVariant.length == 0 &&
            needDeleteProductVariant.length == 0) {
          for (int a = 0; a < productVariantList.length; a++) {
            ProductVariant? getProductVariant = await PosDatabase.instance
                .readProductVariantForUpdate(
                    productVariantList[a]['variant_name'],
                    widget.product!.product_sqlite_id.toString());
            int updateBranchLinkProduct = await PosDatabase.instance
                .updateBranchLinkProductForVariant(BranchLinkProduct(
                    sync_status: 1,
                    updated_at: dateTime,
                    stock_type: selectStock == 'Daily Limit' ? '1' : '2',
                    daily_limit: selectStock == 'Daily Limit'
                        ? productVariantList[a]['quantity']
                        : '',
                    daily_limit_amount: selectStock == 'Daily Limit'
                        ? productVariantList[a]['quantity']
                        : '',
                    stock_quantity: selectStock != 'Daily Limit'
                        ? productVariantList[a]['quantity']
                        : '',
                    price: productVariantList[a]['price'],
                    branch_id: branch_id.toString(),
                    product_variant_sqlite_id:
                        getProductVariant!.product_variant_sqlite_id.toString(),
                    product_sqlite_id:
                        widget.product!.product_sqlite_id.toString()));

/*
             ----------------------sync to cloud-------------------------------
*/
            if (connectivityResult == ConnectivityResult.mobile ||
                connectivityResult == ConnectivityResult.wifi) {
              Map responseUpdateBranchLinkProduct = await Domain()
                  .editBranchLinkProductForVariant(
                      branch_id.toString(),
                      widget.product!.product_id.toString(),
                      getProductVariant.product_variant_id.toString(),
                      selectStock == 'Daily Limit'
                          ? productVariantList[a]['quantity']
                          : '',
                      productVariantList[a]['price'],
                      selectStock == 'Daily Limit' ? '1' : '2',
                      selectStock != 'Daily Limit'
                          ? productVariantList[a]['quantity']
                          : '');
              if (responseUpdateBranchLinkProduct['status'] == '1') {
                int syncData = await PosDatabase.instance
                    .updateSyncBranchLinkProductForUpdate(BranchLinkProduct(
                        sync_status: 2,
                        updated_at: dateTime,
                        product_sqlite_id:
                            widget.product!.product_sqlite_id.toString(),
                        product_variant_sqlite_id: getProductVariant
                            .product_variant_sqlite_id
                            .toString()));
              }
            }
/*
            ----------------------end sync--------------------------------------
*/
          }
        }
      } else {
        int updateBranchLinkProduct = await PosDatabase.instance
            .updateBranchLinkProductEdit(BranchLinkProduct(
                sync_status: 1,
                updated_at: dateTime,
                stock_type: selectStock == 'Daily Limit' ? '1' : '2',
                daily_limit: dailyLimitController.value.text,
                daily_limit_amount: dailyLimitController.value.text,
                stock_quantity: stockQuantityController.text,
                price: priceController.text,
                branch_id: branch_id.toString(),
                product_sqlite_id:
                    widget.product!.product_sqlite_id.toString()));

/*
          ------------------------sync to cloud--------------------------------
*/
        if (connectivityResult == ConnectivityResult.mobile ||
            connectivityResult == ConnectivityResult.wifi) {
          Map responseUpdateBranchLinkProduct = await Domain()
              .editBranchLinkProduct(
                  branch_id.toString(),
                  widget.product!.product_id.toString(),
                  dailyLimitController.value.text,
                  priceController.text,
                  selectStock == 'Daily Limit' ? '1' : '2',
                  stockQuantityController.text);
          if (responseUpdateBranchLinkProduct['status'] == '1') {
            int syncData = await PosDatabase.instance
                .updateSyncBranchLinkProductForUpdate(BranchLinkProduct(
                    sync_status: 2,
                    updated_at: dateTime,
                    product_sqlite_id:
                        widget.product!.product_sqlite_id.toString(),
                    product_variant_sqlite_id: '0'));
          }
        }
/*
          ---------------------------end sync----------------------------------
*/
      }
      Fluttertoast.showToast(
          backgroundColor: Color(0xff0c1f32), msg: "Edit Product Success");
      widget.callBack();
      closeDialog(context);
    } catch (error) {
      Fluttertoast.showToast(
          msg: 'something went wrong, please try again later');
      print(error);
    }
  }

  createProduct(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      Product productInserted = await PosDatabase.instance.insertProduct(
          Product(
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
              sync_status: 0,
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));
/*
      ------------------------------sync to cloud------------------------------
*/
      Map response = await Domain().insertProduct(
          nameController.value.text,
          selectCategory!.category_id.toString(),
          descriptionController.value.text,
          priceController.value.text,
          skuController.value.text,
          selectStatus == 'Available Sale' ? '1' : '0',
          selectVariant == 'Have Variant' ? '1' : '0',
          selectStock == 'Daily Limit' ? '1' : '2',
          dailyLimitController.value.text,
          stockQuantityController.value.text,
          selectGraphic == 'Image' ? '2' : '1',
          productColor,
          imageDir != null
              ? basename(imageDir!).replaceAll('image_picker', '')
              : '',
          userObject['company_id']);

      if (response['status'] == '1') {
        int syncData = await PosDatabase.instance.updateSyncProduct(Product(
          product_id: response['product_id'],
          sync_status: 2,
          updated_at: dateTime,
          product_sqlite_id: productInserted.product_sqlite_id,
        ));
      }
/*
------------------------------end sync-----------------------------------------
*/
      if (selectGraphic == 'Image') {
        saveFilePermanently(imageDir!);
        storeImage(productInserted.image!);
      }

      if (switchController.selectedItem.length != 0) {
        for (int i = 0; i < switchController.selectedItem.length; i++) {
          ModifierLinkProduct data = await PosDatabase.instance
              .insertSyncModifierLinkProduct(ModifierLinkProduct(
                  modifier_link_product_id: 0,
                  mod_group_id: switchController.selectedItem[i].toString(),
                  product_id: '0',
                  product_sqlite_id:
                      productInserted.product_sqlite_id.toString(),
                  sync_status: 0,
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));

/*
  --------------------------------sync to cloud---------------------------------
*/
          Map responseModifier = await Domain().insertModifierLinkProduct(
              switchController.selectedItem[i].toString(),
              response['product_id'].toString());
          if (responseModifier['status'] == '1') {
            int syncData = await PosDatabase.instance
                .updateSyncModifierLinkProduct(ModifierLinkProduct(
              modifier_link_product_id: response['modifier_link_product_id'],
              sync_status: 2,
              updated_at: dateTime,
              modifier_link_product_sqlite_id:
                  data.modifier_link_product_sqlite_id,
            ));
          }
/*
  --------------------------------end sync--------------------------------------
*/
        }
      }

      if (selectVariant == 'Have Variant') {
        for (int i = 0; i < variantList.length; i++) {
          VariantGroup group = await PosDatabase.instance
              .insertSyncVariantGroup(VariantGroup(
                  child: [],
                  variant_group_id: 0,
                  product_id: '0',
                  product_sqlite_id:
                      productInserted.product_sqlite_id.toString(),
                  name: variantList[i]['modGroup'],
                  sync_status: 0,
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));
/*
          ----------------------sync to cloud----------------------------------
*/
          Map responseVariantGroup = await Domain().insertVariantGroup(
              variantList[i]['modGroup'], response['product_id'].toString());
          if (responseVariantGroup['status'] == '1') {
            int syncData =
                await PosDatabase.instance.updateSyncVariantGroup(VariantGroup(
              child: [],
              variant_group_id: response['modifier_link_product_id'],
              sync_status: 2,
              updated_at: dateTime,
              variant_group_sqlite_id: group.variant_group_sqlite_id,
            ));
          }
/*
          -----------------------end sync--------------------------------------
*/

          for (int j = 0; j < variantList[i]['modItem'].length; j++) {
            VariantItem item = await PosDatabase.instance.insertSyncVariantItem(
                VariantItem(
                    variant_item_id: 0,
                    variant_group_id:
                        responseVariantGroup['variant_group_id'].toString(),
                    name: variantList[i]['modItem'][j],
                    sync_status: 0,
                    created_at: dateTime,
                    updated_at: '',
                    soft_delete: ''));
/*
              -------------------------sync to cloud--------------------------
*/
            Map responseVariantItem = await Domain().insertVariantItem(
                variantList[i]['modItem'][j],
                responseVariantGroup['variant_group_id'].toString());
            if (responseVariantItem['status'] == '1') {
              int syncData =
                  await PosDatabase.instance.updateSyncVariantItem(VariantItem(
                variant_item_id: responseVariantItem['variant_item_id'],
                sync_status: 2,
                updated_at: dateTime,
                variant_item_sqlite_id: item.variant_item_sqlite_id,
              ));
            }
/*
              --------------------------end sync-------------------------------
*/

          }
        }

        for (int k = 0; k < productVariantList.length; k++) {
          // if (responseProductVariant['status'] == '1') {}
          ProductVariant variant = await PosDatabase.instance
              .insertSyncProductVariant(ProductVariant(
                  product_variant_id: 0,
                  product_id: response['product_id'].toString(),
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
                  sync_status: 0,
                  created_at: dateTime,
                  updated_at: '',
                  soft_delete: ''));
/*
            ------------------------sync to cloud------------------------------
*/
          Map responseProductVariant = await Domain().insertProductVariant(
              response['product_id'].toString(),
              productVariantList[k]['variant_name'],
              productVariantList[k]['SKU'],
              productVariantList[k]['price'],
              selectStock == 'Daily Limit' ? '1' : '2',
              productVariantList[k]['quantity']);

/*
            -------------------------end sync----------------------------------
*/

          Map responseBranchLinkProduct = await Domain()
              .insertBranchLinkProduct(
                  branch_id.toString(),
                  response['product_id'].toString(),
                  '1',
                  variant.product_variant_id.toString(),
                  branch_id.toString() + variant.SKU.toString(),
                  variant.price,
                  selectStock == 'Daily Limit' ? '1' : '2',
                  selectStock == 'Daily Limit'
                      ? variant.daily_limit
                      : variant.stock_quantity);
          if (responseBranchLinkProduct['status'] == '1') {
            BranchLinkProduct variantBranchProduct = await PosDatabase.instance
                .insertBranchLinkProduct(BranchLinkProduct(
                    branch_link_product_id:
                        responseBranchLinkProduct['branch_link_product_id'],
                    branch_id: branch_id.toString(),
                    product_id: response['product_id'].toString(),
                    has_variant: '1',
                    product_variant_id: variant.product_variant_id.toString(),
                    b_SKU: branch_id.toString() + variant.SKU.toString(),
                    price: variant.price,
                    stock_type: selectStock == 'Daily Limit' ? '1' : '2',
                    daily_limit:
                        selectStock == 'Daily Limit' ? variant.daily_limit : '',
                    daily_limit_amount:
                        selectStock == 'Daily Limit' ? variant.daily_limit : '',
                    stock_quantity: selectStock != 'Daily Limit'
                        ? variant.stock_quantity
                        : '',
                    created_at: dateTime,
                    updated_at: '',
                    soft_delete: ''));

            final splitted = productVariantList[k]['variant_name'].split(' | ');
            for (int l = 0; l < splitted.length; l++) {
              VariantItem? item =
                  await PosDatabase.instance.readVariantItem(splitted[l]);
              Map responseVariantDetail = await Domain()
                  .insertProductVariantDetail(
                      variant.product_variant_id.toString(),
                      item!.variant_item_id.toString());
              if (responseVariantDetail['status'] == '1') {
                ProductVariantDetail variantdetail = await PosDatabase.instance
                    .insertProductVariantDetail(ProductVariantDetail(
                        product_variant_detail_id:
                            responseVariantDetail['product_detail_id'],
                        product_variant_id:
                            variant.product_variant_id.toString(),
                        variant_item_id: item.variant_item_id.toString(),
                        created_at: dateTime,
                        updated_at: '',
                        soft_delete: ''));
              }
            }
          }
        }
      } else {
        Map responseBranchLinkProduct = await Domain().insertBranchLinkProduct(
            branch_id.toString(),
            response['product_id'].toString(),
            '0',
            '',
            branch_id.toString() + skuController.value.text,
            priceController.value.text,
            selectStock == 'Daily Limit' ? '1' : '2',
            selectStock == 'Daily Limit'
                ? dailyLimitController.value.text
                : stockQuantityController.value.text);
        if (responseBranchLinkProduct['status'] == '1') {
          BranchLinkProduct branchProduct = await PosDatabase.instance
              .insertBranchLinkProduct(BranchLinkProduct(
                  branch_link_product_id:
                      responseBranchLinkProduct['branch_link_product_id'],
                  branch_id: branch_id.toString(),
                  product_id: response['product_id'].toString(),
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
      Fluttertoast.showToast(
          backgroundColor: Color(0xff0c1f32), msg: "Create Product Success");
      widget.callBack();
      closeDialog(context);
    } catch (error) {
      Fluttertoast.showToast(msg: 'Something went wrong. Please try again');
      print(error);
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

  deleteProduct(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? branch_id = prefs.getInt('branch_id');
      var connectivityResult = await (Connectivity().checkConnectivity());
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());

      // if(widget.product!.image != '' || widget.product!.image != null ){
      //   deleteFile(widget.product!.image);
      // }

      // if(widget.product!.has_variant == '1'){
      //   List<VariantGroup> variantGroupData = await PosDatabase.instance
      //       .readAllVariantGroup(widget.product!.product_sqlite_id.toString());
      //
      //   for (int i = 0; i < variantGroupData.length; i++) {
      //     int deleteAllVariantItem = await PosDatabase.instance
      //         .deleteAllVariantitem(VariantItem(
      //         sync_status: 1,
      //         soft_delete: dateTime,
      //         variant_group_sqlite_id:
      //         variantGroupData[i].variant_group_sqlite_id.toString()));
      //   }
      //
      //   List<ProductVariant> productVariantData = await PosDatabase.instance
      //       .readProductVariant(widget.product!.product_sqlite_id.toString());
      //
      //   for (int j = 0; j < productVariantData.length; j++) {
      //     int deleteAllProductVariantDetail = await PosDatabase.instance
      //         .deleteAllProductVariantDetail(ProductVariantDetail(
      //         sync_status: 1,
      //         soft_delete: dateTime,
      //         product_variant_sqlite_id: productVariantData[j]
      //             .product_variant_sqlite_id
      //             .toString()));
      //   }
      //   int deleteAllVariantGroup = await PosDatabase.instance
      //       .deleteAllVariantGroup(VariantGroup(
      //       child: [],
      //       sync_status: 1,
      //       soft_delete: dateTime,
      //       product_sqlite_id: widget.product!.product_sqlite_id.toString()));
      //
      //   int deleteAllProductVariant = await PosDatabase.instance
      //       .deleteAllProductVariant(ProductVariant(
      //       sync_status: 1,
      //       soft_delete: dateTime,
      //       product_sqlite_id: widget.product!.product_sqlite_id.toString()));
      //
      // }



      // int deleteProduct = await PosDatabase.instance.deleteProduct(Product(
      //     soft_delete: dateTime,
      //     sync_status: 1,
      //     product_sqlite_id: widget.product!.product_sqlite_id));

      int deleteProductBranch = await PosDatabase.instance
          .deleteAllProductBranch(BranchLinkProduct(
              sync_status: 1,
              soft_delete: dateTime,
              product_sqlite_id: widget.product!.product_sqlite_id.toString()));

      // int deleteModifierLinkProduct = await PosDatabase.instance
      //     .deleteModifierLinkProduct(ModifierLinkProduct(
      //         soft_delete: dateTime,
      //         sync_status: 1,
      //         product_sqlite_id: widget.product!.product_sqlite_id.toString()));

/*
        -------------------------sync to cloud---------------------------------
*/
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        Map response = await Domain().deleteProduct(
            widget.product!.product_id.toString(), branch_id.toString());
        if (response['status'] == '1') {
          // int syncProduct =
          //     await PosDatabase.instance.updateSyncProduct(Product(
          //   product_id: widget.product!.product_id,
          //   sync_status: 2,
          //   updated_at: dateTime,
          //   product_sqlite_id: widget.product!.product_sqlite_id,
          // ));

          int syncBranchLinkProduct = await PosDatabase.instance
              .updateSyncBranchLinkProductForDeleteAll(BranchLinkProduct(
            sync_status: 2,
            updated_at: dateTime,
            product_sqlite_id: widget.product!.product_sqlite_id.toString(),
          ));
          // int syncModifierLinkProduct = await PosDatabase.instance
          //     .updateSyncModifierLinkProductForUpdate(ModifierLinkProduct(
          //   sync_status: 2,
          //   updated_at: dateTime,
          //   product_sqlite_id: widget.product!.product_sqlite_id.toString(),
          // ));

          // int syncVariantGroup = await PosDatabase.instance
          //     .updateSyncVariantGroupForDelete(VariantGroup(
          //   child: [],
          //   sync_status: 2,
          //   updated_at: dateTime,
          //   product_sqlite_id: widget.product!.product_sqlite_id.toString(),
          // ));
          //
          // for (int i = 0; i < variantGroupData.length; i++) {
          //   int syncVariantItem = await PosDatabase.instance
          //       .updateSyncVariantItemForUpdate(VariantItem(
          //     sync_status: 2,
          //     updated_at: dateTime,
          //     variant_group_sqlite_id:
          //         variantGroupData[i].variant_group_sqlite_id.toString(),
          //   ));
          // }

          // int syncProductVariant = await PosDatabase.instance
          //     .updateSyncProductVariantForDelete(ProductVariant(
          //   sync_status: 2,
          //   updated_at: dateTime,
          //   product_sqlite_id: widget.product!.product_sqlite_id.toString(),
          // ));
          //
          // for (int j = 0; j < productVariantData.length; j++) {
          //   int syncProductVariantDetail = await PosDatabase.instance
          //       .updateSyncProductVariantDetailForUpdate(ProductVariantDetail(
          //     sync_status: 2,
          //     updated_at: dateTime,
          //     product_variant_sqlite_id:
          //         productVariantData[j].product_variant_sqlite_id.toString(),
          //   ));
          // }
        }
      }
/*
      ---------------------------end sync--------------------------------------
*/
      widget.callBack();
      closeDialog(context);
      Fluttertoast.showToast(msg: "delete Product Success");
    } catch (error) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFFC107), msg: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return isLoading != true
          ? AlertDialog(
              title: Row(
                children: [
                  Text(
                    isAdd ? "Add Product" : "Edit Product",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  // widget.product!.product_id == null
                  //     ? Container()
                  //     : IconButton(
                  //         icon: const Icon(Icons.delete_outlined),
                  //         color: Colors.red,
                  //         onPressed: () async {
                  //           if (await confirm(
                  //             context,
                  //             title: Text(
                  //                 '${AppLocalizations.of(context)?.translate('confirm')}'),
                  //             content: Text(
                  //                 '${AppLocalizations.of(context)?.translate('would you like to remove?')}'),
                  //             textOK: Text(
                  //                 '${AppLocalizations.of(context)?.translate('yes')}'),
                  //             textCancel: Text(
                  //                 '${AppLocalizations.of(context)?.translate('no')}'),
                  //           )) {
                  //             return deleteProduct(context);
                  //           }
                  //         },
                  //       ),
                ],
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
                                enabled: isAdd? true : false,
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
                                enabled: isAdd? true : false,
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
                          onChanged: isAdd? (Categories? value) {
                            setState(() {
                              selectCategory = value!;
                              print(selectCategory!.category_sqlite_id);
                            });
                          } : null,
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
                          onChanged: isAdd? (value) => setState(() {
                            selectStock = value!;
                          }) : null,
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
                          ? selectVariant == 'Have Variant' ? Container() : ValueListenableBuilder(
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
                          : selectVariant == 'Have Variant' ? Container() : ValueListenableBuilder(
                              valueListenable: stockQuantityController,
                              builder: (context, TextEditingValue value, __) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    enabled: false,
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
                      selectVariant == 'Have Variant' ? Container() : ValueListenableBuilder(
                          valueListenable: priceController,
                          builder: (context, TextEditingValue value, __) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                enabled: false,
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
                                enabled: isAdd? true : false,
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
                            disableItems: List.generate(modifierElement.length,
                                    (index) => modifierElement[index].name!),
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
                            onItemSelected: isAdd? (data) {
                              print(data);
                            }:null,
                          ),
                        ],
                      ),
                      widget.product!.product_id == null
                          ? Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: RadioGroup<String>.builder(
                                direction: Axis.horizontal,
                                groupValue: selectVariant,
                                horizontalAlignment:
                                    MainAxisAlignment.spaceBetween,
                                onChanged: (value) => setState(() {
                                  selectVariant = value!;
                                }),
                                items: productVariant,
                                textStyle: TextStyle(
                                    fontSize: 15, color: color.buttonColor),
                                itemBuilder: (item) => RadioButtonBuilder(
                                  item,
                                ),
                                activeColor: color.backgroundColor,
                              ),
                            )
                          : Container(),
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
                                        // trailing: IconButton(
                                        //   icon: Icon(Icons.close),
                                        //   onPressed: () {
                                        //     setState(() {
                                        //       variantList.removeAt(index);
                                        //       createProductVariantList();
                                        //     });
                                        //   },
                                        // ),
                                      );
                                    }),
                                // variantList.length < 3
                                //     ? Padding(
                                //         padding: const EdgeInsets.fromLTRB(
                                //             15, 0, 15, 0),
                                //         child: ElevatedButton(
                                //           child: Text("Add Variant"),
                                //           onPressed: () {
                                //             openVariantOptionDialog(context);
                                //           },
                                //           style: ElevatedButton.styleFrom(
                                //               primary: color.backgroundColor,
                                //               textStyle: TextStyle(
                                //                   color: Colors.white70,
                                //                   fontWeight: FontWeight.bold)),
                                //         ),
                                //       )
                                //     : Container(),
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
                                                              DataCell(Text(productVariantList[index]['variant_name'])),
                                                              DataCell(
                                                                Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child:
                                                                      TextField(
                                                                    keyboardType: TextInputType.number,
                                                                    readOnly: true,
                                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                    controller: TextEditingController(text: productVariantList[index]['quantity']),
                                                                    decoration: InputDecoration(),
                                                                    onChanged:
                                                                        (value) {
                                                                      changeValue(
                                                                          'quantity',
                                                                          value,
                                                                          productVariantList[index]);
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child:
                                                                      TextField(
                                                                    keyboardType: TextInputType.number,
                                                                    readOnly: true,
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter.digitsOnly
                                                                    ],
                                                                    controller:
                                                                        TextEditingController(text: productVariantList[index]['price']),
                                                                    decoration:
                                                                        InputDecoration(),
                                                                    onChanged:
                                                                        (value) {
                                                                      changeValue(
                                                                          'price',
                                                                          value,
                                                                          productVariantList[index]);
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
                          onChanged: isAdd? (value) => setState(() {
                            selectGraphic = value!;
                          }):null,
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
                                    onPressed: isAdd? () {
                                      getImage(ImageSource.gallery);
                                    }:null,
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
                                    onPressed: isAdd? () {
                                      getImage(ImageSource.camera);
                                    }:null,
                                    style: ElevatedButton.styleFrom(
                                        primary: color.backgroundColor,
                                        textStyle: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            )
                          : isAdd ? MaterialColorPicker(
                              physics: NeverScrollableScrollPhysics(),
                              allowShades: false,
                              selectedColor: Color(int.parse(
                                  productColor.replaceAll('#', '0xff'))),
                              circleSize: 190,
                              shrinkWrap: true,
                              onMainColorChange: isAdd? (color) {
                                var hex =
                                    '#${color!.value.toRadixString(16).substring(2)}';
                                productColor = hex;
                              }:null,
                            ):Container(),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: RadioGroup<String>.builder(
                          direction: Axis.horizontal,
                          groupValue: selectStatus,
                          horizontalAlignment: MainAxisAlignment.spaceBetween,
                          onChanged: (value) => setState(() {
                              selectStatus = value!;
                            }),
                          // isAdd? (value) => setState(() {
                          //   selectStatus = value!;
                          // }):null,
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
                  child: isAdd ? Text('Add') : Text('Edit'),
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

  Future<String> get  _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<Directory> get _localDirectory async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final path = await _localPath;
    return Directory('$path/assets/' +
        userObject['company_id'] +
        '/' +
        widget.product!.image!);
  }

  Future<int> deleteFile(image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      final path = await _localPath;
      final file = Directory('$path/assets/' +
          userObject['company_id'] +
          '/' +image);
      await file.delete(recursive: true);
      return 1;
    } catch (e) {
      return 0;
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

  storeImage(String imageName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    String path = await _localPath;
    Directory imagePath =
        Directory('$path/assets/' + userObject['company_id'] + '/$imageName');
    File afterCompress = await compressFile(File(imagePath.path));
    List<int> imageBytes = await afterCompress.readAsBytes();
    final splitted = imageName.split('.');
    String base64Image =
        "data:image/${splitted[1]};base64," + base64Encode(imageBytes);
    Map response = await Domain()
        .storeProductImage(base64Image, imageName, userObject['company_id']);
    if (response['status'] == '1') {
      print("store successfully");
    } else {
      print("oh no bug");
    }
  }

  Future<int> deleteImage(String imageName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map response = await Domain().deleteProductImage(imageName, userObject['company_id']);
    if (response['status'] == '1') {
      return 1;
    } else {
      return 0;
    }
  }

  Future<File> compressFile(File file) async {
    File compressedFile = await FlutterNativeImage.compressImage(
      file.path,
      quality: 25,
    );
    return compressedFile;
  }
}
