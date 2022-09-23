import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class Domain {
  static var domain = 'https://pos.lkmng.com/';
  static Uri login = Uri.parse(domain + 'mobile-api/login/index.php');
  static Uri branch = Uri.parse(domain + 'mobile-api/branch/index.php');
  static Uri device = Uri.parse(domain + 'mobile-api/device/index.php');
  static Uri user = Uri.parse(domain + 'mobile-api/user/index.php');
  static Uri table = Uri.parse(domain + 'mobile-api/table/index.php');
  static Uri dining_option =
      Uri.parse(domain + 'mobile-api/dining_option/index.php');
  static Uri tax = Uri.parse(domain + 'mobile-api/tax/index.php');
  static Uri categories = Uri.parse(domain + 'mobile-api/categories/index.php');
  static Uri promotion = Uri.parse(domain + 'mobile-api/promotion/index.php');
  static Uri customer = Uri.parse(domain + 'mobile-api/customer/index.php');
  static Uri bill = Uri.parse(domain + 'mobile-api/bill/index.php');
  static Uri payment = Uri.parse(domain + 'mobile-api/payment/index.php');
  static Uri refund = Uri.parse(domain + 'mobile-api/refund/index.php');
  static Uri modifier = Uri.parse(domain + 'mobile-api/modifier/index.php');
  static Uri product = Uri.parse(domain + 'mobile-api/product/index.php');
  static Uri variant = Uri.parse(domain + 'mobile-api/variant/index.php');
  static Uri order = Uri.parse(domain + 'mobile-api/order/index.php');
  static Uri sale = Uri.parse(domain + 'mobile-api/sale/index.php');
  // static Uri task = Uri.parse(domain + 'mobile_api/task/index.php');
  // static Uri notification =
  //     Uri.parse(domain + 'mobile_api/notification/index.php');
  //
  // static Uri proofImgPath = Uri.parse(domain + 'mobile_api/task/image/');

  /*
  * login
  * */
  userlogin(email, password) async {
    try {
      var response = await http.post(Domain.login, body: {
        'login': '1',
        'password': password,
        'email': email,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * Forget Password
  * */
  forgetPassword(email) async {
    try {
      var response = await http.post(Domain.login, body: {
        'resetPassword': '1',
        'email': email,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get company branch
  * */
  getCompanyBranch(company_id) async {
    try {
      var response = await http.post(Domain.branch, body: {
        'getAllCompanyBranch': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch device
  * */
  getBranchDevice(branch_id) async {
    try {
      var response = await http.post(Domain.device, body: {
        'getBranchDevice': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all branch user
  * */
  getAllUser(company_id) async {
    try {
      var response = await http.post(Domain.user, body: {
        'getAllUser': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all branch user
  * */
  getBranchLinkUser(branch_id) async {
    try {
      var response = await http.post(Domain.user, body: {
        'getBranchLinkUser': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all branch table
  * */
  getAllTable(branch_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'getAllTable': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert branch table
  * */
  insertTable(seats, number, branch_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'addTable': '1',
        'seats': seats,
        'number': number,
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch table
  * */
  editTable(seats, number, table_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'editTable': '1',
        'seats': seats,
        'number': number,
        'table_id': table_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete branch table
  * */
  deleteBranchTable(table_id) async {
    try {
      var response = await http.post(Domain.table, body: {
        'delete': '1',
        'table_id': table_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all dining option
  * */
  getAllDiningOption(company_id) async {
    try {
      var response = await http.post(Domain.dining_option, body: {
        'getAllDiningOption': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link dining option
  * */
  getBranchLinkDiningOption(branch_id) async {
    try {
      var response = await http.post(Domain.dining_option, body: {
        'getBranchLinkDiningOption': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all company tax
  * */
  getAllTax(company_id) async {
    try {
      var response = await http.post(Domain.tax, body: {
        'getAllTax': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link tax
  * */
  getBranchLinkTax(branch_id) async {
    try {
      var response = await http.post(Domain.tax, body: {
        'getBranchLinkTax': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get tax link dining
  * */
  getTaxLinkDining(branch_id) async {
    try {
      var response = await http.post(Domain.tax, body: {
        'getTaxLinkDining': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all categories
  * */
  getAllCategory(company_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'getAllCategory': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert categories to cloud
  * */
  insertCategory(color, name, company_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'addCategories': '1',
        'color': color,
        'name': name,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert categories to cloud
  * */
  editCategory(color, name, category_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'editCategories': '1',
        'color': color,
        'name': name,
        'category_id': category_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert categories to cloud
  * */
  deleteCategory(category_id) async {
    try {
      var response = await http.post(Domain.categories, body: {
        'deleteCategories': '1',
        'category_id': category_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all promotion
  * */
  getAllPromotion(company_id) async {
    try {
      var response = await http.post(Domain.promotion, body: {
        'getAllPromotion': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link promotion
  * */
  getBranchLinkPromotion(branch_id) async {
    try {
      var response = await http.post(Domain.promotion, body: {
        'getBranchLinkPromotion': '1',
        'branch_id': branch_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get customer
  * */
  getAllCustomer(company_id) async {
    try {
      var response = await http.post(Domain.customer, body: {
        'getAllCustomer': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get bill
  * */
  getAllBill(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.bill, body: {
        'getAllCustomer': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get payment option
  * */
  getPaymentLinkCompany(company_id) async {
    try {
      var response = await http.post(Domain.payment,
          body: {'getPaymentLinkCompany': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get refund
  * */
  getAllRefund(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.refund, body: {
        'getAllRefund': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get modifier group name
  * */
  getModifierGroup(company_id) async {
    try {
      var response = await http.post(Domain.modifier,
          body: {'getModifierGroup': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get modifier item
  * */
  getModifierItem(company_id) async {
    try {
      var response = await http.post(Domain.modifier,
          body: {'getModifierItem': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get branch link modifier
  * */
  getBranchLinkModifier(branch_id) async {
    try {
      var response = await http.post(Domain.modifier,
          body: {'getBranchLinkModifier': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get product
  * */
  getAllProduct(company_id) async {
    try {
      var response = await http.post(Domain.product,
          body: {'getAllProduct': '1', 'company_id': company_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product
  * */
  insertProduct(
      name,
      category_id,
      description,
      price,
      SKU,
      availableSale,
      hasVariant,
      stockType,
      dailyLimit,
      stockQuantity,
      graphic,
      color,
      imageName,
      company_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProduct': '1',
        'pName': name,
        'pCategories': category_id,
        'pDescription': description,
        'pPrice': price,
        'pSKU': SKU,
        'availableSale': availableSale,
        'hasVariant': hasVariant,
        'stockType': stockType,
        'dailyLimit': dailyLimit,
        'stockQuantity': stockQuantity,
        'graphic': graphic,
        'color': color,
        'image_name': imageName,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * update product
  * */
  updateProduct(
      name,
      category_id,
      description,
      price,
      SKU,
      availableSale,
      hasVariant,
      stockType,
      dailyLimit,
      stockQuantity,
      graphic,
      color,
      imageName,
      product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'editProduct': '1',
        'pID': product_id,
        'pName': name,
        'pCategories': category_id,
        'pDescription': description,
        'pPrice': price,
        'pSKU': SKU,
        'availableSale': availableSale,
        'hasVariant': hasVariant,
        'stockType': stockType,
        'dailyLimit': dailyLimit,
        'stockQuantity': stockQuantity,
        'graphic': graphic,
        'color': color,
        'imageName': imageName,

      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product
  * */
  deleteProduct(product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteProduct': '1',
        'product_id': product_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }


  /*
  * get branch link product
  * */
  getBranchLinkProduct(branch_id) async {
    try {
      var response = await http.post(Domain.product,
          body: {'getBranchLinkProduct': '1', 'branch_id': branch_id});
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert branch link product
  * */
  insertBranchLinkProduct(branch_id, product_id, hasVariant, product_variant_id,
      SKU, price, stockType, quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addBranchLinkProduct': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'hasVariant': hasVariant,
        'product_variant_id': product_variant_id,
        'b_SKU': SKU,
        'price': price,
        'stockType': stockType,
        'quantity': quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch link product
  * */
  editBranchLinkProductForVariant(branch_id, product_id, product_variant_id,
     daily_limit, price, stockType, stock_quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'updateBranchLinkProductForVariant': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'product_variant_id': product_variant_id,
        'price': price,
        'stockType': stockType,
        'daily_limit' : daily_limit,
        'stock_quantity': stock_quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * edit branch link product
  * */
  editBranchLinkProduct(branch_id, product_id,
      daily_limit, price, stockType, stock_quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'updateBranchLinkProduct': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'price': price,
        'stockType': stockType,
        'daily_limit' : daily_limit,
        'stock_quantity': stock_quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete branch link product
  * */
  deleteBranchLinkProduct(branch_id, product_id, product_variant_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteBranchLinkProduct': '1',
        'branch_id': branch_id,
        'product_id': product_id,
        'product_variant_id': product_variant_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get modifier link product
  * */
  getModifierLinkProduct(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'getModifierLinkProduct': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product modifier
  * */
  insertModifierLinkProduct(mod_group_id, product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProductModifier': '1',
        'mod_group_id': mod_group_id,
        'product_id': product_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product modifier
  * */
  deleteModifierLinkProduct(product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteModLinkProduct': '1',
        'product_id': product_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get variant group
  * */
  getVariantGroup(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getVariantGroup': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert variant group
  * */
  insertVariantGroup(name, product_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addVariantGroup': '1',
        'name': name,
        'product_id': product_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete variant group
  * */
  deleteVariantGroup(product_id,variant_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteVariantGroup': '1',
        'product_id': product_id,
        'variant_group_id': variant_group_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get variant item
  * */
  getVariantItem(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getVariantItem': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert variant item
  * */
  insertVariantItem(name, variant_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addVariantItem': '1',
        'name': name,
        'variant_group_id': variant_group_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete variant item
  * */
  deleteVariantItem(variant_group_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteVariantItem': '1',
        'variant_group_id': variant_group_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get product variant
  * */
  getProductVariant(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getProductVariant': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product variant
  * */
  insertProductVariant(
      product_id, name, SKU, price, stockType, quantity) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProductVariant': '1',
        'product_id': product_id,
        'name': name,
        'SKU': SKU,
        'price': price,
        'stockType': stockType,
        'quantity': quantity
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product variant
  * */
  deleteProductVariant(product_id, product_variant_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteProductVariant': '1',
        'product_id': product_id,
        'product_variant_id': product_variant_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get product variant detail
  * */
  getProductVariantDetail(company_id) async {
    try {
      var response = await http.post(Domain.variant, body: {
        'getProductVariantDetail': '1',
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * insert product variant detail
  * */
  insertProductVariantDetail(product_variant_id, variant_item_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'addProductVariantDetail': '1',
        'product_variant_id': product_variant_id,
        'variant_item_id': variant_item_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete product variant detail
  * */
  deleteProductVariantDetail(product_variant_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteProductVariantDetail': '1',
        'product_variant_id': product_variant_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order
  * */
  getAllOrder(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'getAllOrder': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order cache
  * */
  getAllOrderCache(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'getAllOrderCache': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order detail
  * */
  getAllOrderDetail(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'getAllOrderDetail': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get all order modifier detail
  * */
  getAllOrderModifierDetail(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.order, body: {
        'getAllOrderModifierDetail': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * get sale
  * */
  getSale(company_id, branch_id) async {
    try {
      var response = await http.post(Domain.sale, body: {
        'getSale': '1',
        'company_id': company_id,
        'branch_id': branch_id
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * store image to cloud
  * */
  storeProductImage(image, image_name, company_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'storeImage': '1',
        'image': image,
        'image_name': image_name,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  /*
  * delete image from cloud
  * */
  deleteProductImage(image_name, company_id) async {
    try {
      var response = await http.post(Domain.product, body: {
        'deleteImage': '1',
        'image_name': image_name,
        'company_id': company_id,
      });
      return jsonDecode(response.body);
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }
}
