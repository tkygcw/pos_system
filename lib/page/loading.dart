import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/bill.dart';
import 'package:pos_system/object/branch_link_dining_option.dart';
import 'package:pos_system/object/branch_link_modifier.dart';
import 'package:pos_system/object/branch_link_product.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/categories.dart';
import 'package:pos_system/object/modifier_group.dart';
import 'package:pos_system/object/modifier_item.dart';
import 'package:pos_system/object/modifier_link_product.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/object/product_variant.dart';
import 'package:pos_system/object/product_variant_detail.dart';
import 'package:pos_system/object/promotion.dart';
import 'package:pos_system/object/refund.dart';
import 'package:pos_system/object/sale.dart';
import 'package:pos_system/object/table.dart';
import 'package:pos_system/object/tax_link_dining.dart';
import 'package:pos_system/object/user.dart';
import 'package:pos_system/object/variant_group.dart';
import 'package:pos_system/object/variant_item.dart';
import 'package:pos_system/page/pos_pin.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/domain.dart';
import '../notifier/theme_color.dart';
import '../object/branch_link_user.dart';
import '../object/customer.dart';
import '../object/dining_option.dart';
import '../object/tax.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
      _createProductImgFolder();
      getAllUser();
      getAllTable();
      getBranchLinkUser();
      getAllDiningOption();
      getBranchLinkDiningOption();
      getAllTax();
      getBranchLinkTax();
      getTaxLinkDining();
      getAllCategory();
      getAllPromotion();
      getBranchLinkPromotion();
      getAllCustomer();
      getAllBill();
      getPaymentLinkCompany();
      getAllRefund();
      getModifierGroup();
      getModifierItem();
      getBranchLinkModifier();
      getAllProduct();
      getBranchLinkProduct();
      getModifierLinkProduct();
      getVariantGroup();
      getVariantItem();
      getProductVariant();
      getProductVariantDetail();
      getAllOrder();
      getAllOrderCache();
      getAllOrderDetail();
      getSale();


    // Go to Page2 after 5s.
    Timer(Duration(seconds: 4), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        backgroundColor: color.backgroundColor,
        body: Center(
            child: Image.file(File(
                '/data/user/0/com.example.pos_system/files/assets/img/output-onlinegiftools.gif'))),
      );
    });
  }

/*
  sava company user to database
*/
  getAllUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllUser(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['user'];
      for (var i = 0; i < responseJson.length; i++) {
        User user = await PosDatabase.instance
            .insertUser(User.fromJson(responseJson[i]));
        // if (user != '') {
        //   Navigator.of(context).pushReplacement(MaterialPageRoute(
        //     builder: (context) => PosPinPage(),
        //   ));
        // }
      }
    }
  }

/*
  save branch link user table to database
*/
  getBranchLinkUser() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkUser(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['user'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkUser data = await PosDatabase.instance
            .insertBranchLinkUser(BranchLinkUser.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch table to database
*/
  getAllTable() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getAllTable(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['table'];
      for (var i = 0; i < responseJson.length; i++) {
          PosTable table = await PosDatabase.instance.insertPosTable(
              PosTable.fromJson(responseJson[i]));
        }
      }
    }
  }

/*
  save dining option to database
*/
  getAllDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllDiningOption(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['dining_option'];
      for (var i = 0; i < responseJson.length; i++) {
        DiningOption data = await PosDatabase.instance.insertDiningOption(DiningOption.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch link dining option to database
*/
  getBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkDiningOption(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['dining_option'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkDining data = await PosDatabase.instance
            .insertBranchLinkDining(BranchLinkDining.fromJson(responseJson[i]));
      }
    }
  }

/*
  save tax to database
*/
  getAllTax() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllTax(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['tax'];
      for (var i = 0; i < responseJson.length; i++) {
        Tax data =
            await PosDatabase.instance.insertTax(Tax.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch link tax to database
*/
  getBranchLinkTax() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkTax(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['tax'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkTax data = await PosDatabase.instance
            .insertBranchLinkTax(BranchLinkTax.fromJson(responseJson[i]));
      }
    }
  }

/*
  save tax link dining to database
*/
  getTaxLinkDining() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getTaxLinkDining(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['tax'];
      for (var i = 0; i < responseJson.length; i++) {
        TaxLinkDining data = await PosDatabase.instance
            .insertTaxLinkDining(TaxLinkDining.fromJson(responseJson[i]));
      }
    }
  }

/*
  save categories to database
*/
  getAllCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllCategory(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['categories'];
      for (var i = 0; i < responseJson.length; i++) {
        Categories data = await PosDatabase.instance
            .insertCategories(Categories.fromJson(responseJson[i]));
      }
    }
  }

/*
  save promotion to database
*/
  getAllPromotion() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllPromotion(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['promotion'];
      for (var i = 0; i < responseJson.length; i++) {
        Promotion data = await PosDatabase.instance
            .insertPromotion(Promotion.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch link promotion to database
*/
  getBranchLinkPromotion() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkPromotion(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['promotion'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkPromotion data = await PosDatabase.instance
            .insertBranchLinkPromotion(
                BranchLinkPromotion.fromJson(responseJson[i]));
      }
    }
  }

/*
  save customer to database
*/
  getAllCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllCustomer(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['customer'];
      for (var i = 0; i < responseJson.length; i++) {
        Customer data = await PosDatabase.instance
            .insertCustomer(Customer.fromJson(responseJson[i]));
      }
    }
  }

/*
  save bill to database
*/
  getAllBill() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    Map userObject = json.decode(user!);
    Map data = await Domain()
        .getAllBill(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['bill'];
      for (var i = 0; i < responseJson.length; i++) {
        Bill data = await PosDatabase.instance
            .insertBill(Bill.fromJson(responseJson[i]));
      }
    }
  }

/*
  save payment option to database
*/
  getPaymentLinkCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getPaymentLinkCompany(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['payment'];
      for (var i = 0; i < responseJson.length; i++) {
        PaymentLinkCompany data = await PosDatabase.instance
            .insertPaymentLinkCompany(
                PaymentLinkCompany.fromJson(responseJson[i]));
      }
    }
  }

/*
  save refund to database
*/
  getAllRefund() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    Map userObject = json.decode(user!);
    Map data = await Domain()
        .getAllRefund(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['refund'];
      for (var i = 0; i < responseJson.length; i++) {
        Refund data = await PosDatabase.instance
            .insertRefund(Refund.fromJson(responseJson[i]));
      }
    }
  }

/*
  save modifier group to database
*/
  getModifierGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getModifierGroup(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['modifier'];
      for (var i = 0; i < responseJson.length; i++) {
        ModifierGroup data = await PosDatabase.instance
            .insertModifierGroup(ModifierGroup.fromJson(responseJson[i]));
      }
    }
  }

/*
  save modifier item to database
*/
  getModifierItem() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getModifierItem(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['modifier'];
      for (var i = 0; i < responseJson.length; i++) {
        ModifierItem data = await PosDatabase.instance
            .insertModifierItem(ModifierItem.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch link modifier to database
*/
  getBranchLinkModifier() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkModifier(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['modifier'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkModifier data = await PosDatabase.instance
            .insertBranchLinkModifier(
                BranchLinkModifier.fromJson(responseJson[i]));
      }
    }
  }

/*
  save product to database
*/
  getAllProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllProduct(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['product'];
      for (var i = 0; i < responseJson.length; i++) {
        Product data = await PosDatabase.instance
            .insertProduct(Product.fromJson(responseJson[i]));
      }
    }
  }

/*
  save branch link product to database
*/
  getBranchLinkProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Map data = await Domain().getBranchLinkProduct(branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['product'];
      for (var i = 0; i < responseJson.length; i++) {
        BranchLinkProduct data = await PosDatabase.instance
            .insertBranchLinkProduct(
                BranchLinkProduct.fromJson(responseJson[i]));
      }
    }
  }

/*
  save modifier link product to database
*/
  getModifierLinkProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain()
        .getModifierLinkProduct(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['product'];
      for (var i = 0; i < responseJson.length; i++) {
        ModifierLinkProduct data = await PosDatabase.instance.insertModifierLinkProduct(
                ModifierLinkProduct.fromJson(responseJson[i]));
      }
    }
  }

/*
  save variant group to database
*/
  getVariantGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getVariantGroup(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['variant'];
      for (var i = 0; i < responseJson.length; i++) {
        VariantGroup data = await PosDatabase.instance
            .insertVariantGroup(VariantGroup.fromJson(responseJson[i]));
      }
    }
  }

/*
  save variant item to database
*/
  getVariantItem() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getVariantItem(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['variant'];
      for (var i = 0; i < responseJson.length; i++) {
        VariantItem data = await PosDatabase.instance
            .insertVariantItem(VariantItem.fromJson(responseJson[i]));
      }
    }
  }

/*
  save product variant to database
*/
  getProductVariant() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getProductVariant(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['variant'];
      for (var i = 0; i < responseJson.length; i++) {
        ProductVariant data = await PosDatabase.instance
            .insertProductVariant(ProductVariant.fromJson(responseJson[i]));
      }
    }
  }

/*
  save product variant detail to database
*/
  getProductVariantDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getProductVariantDetail(userObject['company_id']);
    if (data['status'] == '1') {
      List responseJson = data['variant'];
      for (var i = 0; i < responseJson.length; i++) {
        ProductVariantDetail data = await PosDatabase.instance
            .insertProductVariantDetail(
                ProductVariantDetail.fromJson(responseJson[i]));
      }
    }
  }

/*
  save order to database
*/
  getAllOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain()
        .getAllOrder(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['order'];
      for (var i = 0; i < responseJson.length; i++) {
        Order data = await PosDatabase.instance
            .insertOrder(Order.fromJson(responseJson[i]));
      }
    }
  }

/*
  save order cache to database
*/
  getAllOrderCache() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain()
        .getAllOrderCache(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['order'];
      for (var i = 0; i < responseJson.length; i++) {
        OrderCache data = await PosDatabase.instance
            .insertOrderCache(OrderCache.fromJson(responseJson[i]));
      }
    }
  }

/*
  save order detail to database
*/
  getAllOrderDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain()
        .getAllOrderDetail(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['order'];
      for (var i = 0; i < responseJson.length; i++) {
        OrderDetail data = await PosDatabase.instance
            .insertOrderDetail(OrderDetail.fromJson(responseJson[i]));
      }
    }
  }

/*
  save sale to database
*/
  getSale() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data =
        await Domain().getSale(userObject['company_id'], branch_id.toString());
    if (data['status'] == '1') {
      List responseJson = data['sale'];
      for (var i = 0; i < responseJson.length; i++) {
        Sale data = await PosDatabase.instance
            .insertSale(Sale.fromJson(responseJson[i]));
      }
    }
  }

/*
  create folder to save product image
*/
  _createProductImgFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    final folderName = userObject['company_id'];
    final path = Directory(
        "data/user/0/com.example.pos_system/files/assets/$folderName");
    if ((await path.exists())) {
      downloadProductImage(path.path);
    } else {
      path.create();
      downloadProductImage(path.path);
    }
  }

/*
  download product image
*/
  downloadProductImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);
    Map data = await Domain().getAllProduct(userObject['company_id']);
    String url = '';
    String name = '';
    if (data['status'] == '1') {
      List responseJson = data['product'];
      for (var i = 0; i < responseJson.length; i++) {
        Product data = Product.fromJson(responseJson[i]);
        name = data.image!;
        if(data.image !=''){
          url = 'https://pos.lkmng.com/api/gallery/'+userObject['company_id']+'/'+ name;
          final response = await http.get(Uri.parse(url));
          var localPath = path+'/'+name;
          final imageFile = File(localPath);
          await imageFile.writeAsBytes(response.bodyBytes);
        }
      }
    }
  }







