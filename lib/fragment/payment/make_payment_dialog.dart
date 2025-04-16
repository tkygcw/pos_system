import 'dart:async';
import 'dart:convert';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/cupertino.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/fragment/payment/ipay_api.dart';
import 'package:pos_system/fragment/payment/payment_success_dialog.dart';
import 'package:pos_system/notifier/app_setting_notifier.dart';
import 'package:pos_system/notifier/connectivity_change_notifier.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:pos_system/object/app_setting.dart';
import 'package:pos_system/object/branch.dart';
import 'package:pos_system/object/branch_link_promotion.dart';
import 'package:pos_system/object/branch_link_tax.dart';
import 'package:pos_system/object/order.dart';
import 'package:pos_system/object/order_cache.dart';
import 'package:pos_system/object/order_detail.dart';
import 'package:pos_system/object/order_payment_split.dart';
import 'package:pos_system/object/order_promotion_detail.dart';
import 'package:pos_system/object/order_tax_detail.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/printer.dart';
import 'package:pos_system/object/sync_to_cloud.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:developer';
import 'package:crypto/crypto.dart';

import '../../database/domain.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/cart_notifier.dart';
import '../../object/branch_link_dining_option.dart';
import '../../object/cart_product.dart';
import '../../object/modifier_group.dart';
import '../printing_layout/print_receipt.dart';
import '../../object/promotion.dart';
import '../../object/second_display_data.dart';
import '../../object/table.dart';
import '../../object/tax.dart';
import '../../object/variant_group.dart';
import '../../utils/Utils.dart';
import '../logout_dialog.dart';

class MakePayment extends StatefulWidget {
  final int type;
  final int payment_link_company_id;
  final String dining_id;
  final String dining_name;
  final String order_key;
  final Function(String)? callBack;

  const MakePayment(
      {Key? key,
      required this.type,
      required this.payment_link_company_id,
      required this.dining_id,
      required this.dining_name,
      required this.order_key,
      this.callBack
      })
      : super(key: key);

  @override
  State<MakePayment> createState() => _MakePaymentState();
}

class _MakePaymentState extends State<MakePayment> {
  final assetsAudioPlayer = AssetsAudioPlayer();
  final inputController = TextEditingController();
  final ScrollController _controller = ScrollController();
  late StreamController streamController;
  late AppSettingModel _appSettingModel;
  late int _type;
  late int _payment_link_company_id;
  SyncToCloud syncToCloud = SyncToCloud();

  // var type ="0";
  var userInput = '0.00';
  var answer = '';
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final splitAmountController = TextEditingController();
  List<String> branchLinkDiningIdList = [];
  List<PaymentLinkCompany> PaymentLists = [];
  List<Promotion> autoApplyPromotionList = [];
  List<Promotion> appliedPromotionList = [];
  List<String> orderCacheIdList = [];
  List<PosTable> selectedTableList = [];
  List<Printer> printerList = [];
  List<Order> orderList = [];
  List<Tax> taxList = [];
  List<cartProductItem> itemList = [];
  List<OrderPaymentSplit> paymentSplitList = [];
  bool scanning = false;
  bool isopen = false;
  bool chipSelected = false;
  bool hasSelectedPromo = false;
  bool hasPromo = true, isLogOut = false;
  int taxRate = 0;
  int diningOptionID = 0;
  int count = 0;
  double total = 0.0;
  double promo = 0.0;
  double selectedPromo = 0.0;
  double selectedPromoAmount = 0.0;
  double taxAmount = 0.0;
  double priceIncAllTaxes = 0.0;
  double priceIncTaxes = 0.0;
  double discountPrice = 0.0;
  double promoAmount = 0.0;
  double totalAmount = 0.0;
  double tableOrderPrice = 0.0;
  double rounding = 0.0;
  double paymentSplitAmount = 0.0;
  String diningName = '';
  String selectedPromoRate = '';
  String promoName = '';
  String promoRate = '';
  String localTableUseId = '';
  String orderCacheId = '';
  String ipay_code = '';
  String? allPromo = '';
  late String finalAmount = '';
  late String statisFinalAmount = '';
  String change = '0.00';
  String? orderId, orderKey;
  String? order_value, order_tax_value, order_promotion_value;
  int myCount = 0, initLoad = 0;
  late Map branchObject;
  bool isButtonDisable = false, willPop = true;
  String orderCacheSqliteId = '';
  bool isload = false;
  late bool split_payment = false;
  bool isButtonDisabled = false;
  bool paymentSplitDialog = false;
  String order_split_payment_link_company_id = '';

  // Array of button
  final List<String> buttons = [
    '7', //0
    '8', //1
    '9', //2
    'C', //3
    '4', //4
    '5', //5
    '6', //6
    'DEL', //7
    '1', //8
    '2', //9
    '3', //10
    '', //11
    '00', //12
    '0', //13
    '.', //14
    '', //15
    '20.00', //16
    '50.00', //17
    '100.00', //18
    'GO', //19
  ];

  void _scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _payment_link_company_id = widget.payment_link_company_id;
    streamController = StreamController();
    readAllPrinters();
    readAllBranchLinkDiningOption();
    readBranchPref();
    readSpecificPaymentMethod();
    readAllOrder();
    readPaymentMethod();
    getAllPaymentSplit(widget.order_key);
  }

  @override
  void dispose() {
    inputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  reInitSecondDisplay({isWillPop, CartModel? cart}) async {
    if (isWillPop == true) {
      await displayManager.transferDataToPresentation("init");
    } else {
      if(cart != null){
        SecondDisplayData data = SecondDisplayData(
            tableNo: getSelectedTable(),
            itemList: cart.cartNotifierItem,
            subtotal: cart.cartNotifierPayment[0].subtotal.toStringAsFixed(2),
            totalDiscount: getTotalDiscount(),
            totalTax: getTotalTax(),
            amount: cart.cartNotifierPayment[0].amount.toStringAsFixed(2),
            rounding: cart.cartNotifierPayment[0].rounding.toStringAsFixed(2),
            finalAmount: cart.cartNotifierPayment[0].finalAmount,
            payment_link_company_id: widget.payment_link_company_id,
            selectedOption: cart.selectedOption
        );
        await displayManager.transferDataToPresentation(jsonEncode(data));
      }
    }
  }

  readAllPrinters() async {
    printerList = await PrintReceipt().readAllPrinters();
  }

  closeDialog(BuildContext context) {
    return Navigator.of(context).pop(true);
  }

  Future<Future<Object?>> openLogOutDialog() async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: LogoutConfirmDialog(),
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

  @override
  Widget build(BuildContext context) {
    if (controller != null && mounted && result == null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
        return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
          _appSettingModel = appSettingModel;
          return Consumer<ConnectivityChangeNotifier>(builder: (context, ConnectivityChangeNotifier connectivity, child) {
          getReceiptPaymentDetail(cart);
          //getSubTotal(cart);
          getCartItemList(cart);
          if (initLoad == 0 && notificationModel.hasSecondScreen == true && notificationModel.secondScreenEnable == true) {
            reInitSecondDisplay(cart: cart);
            // if(notificationModel.secondScreenEnable == true){
            //   reInitSecondDisplay(cart: cart);
            // }
            initLoad++;
          }
          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 900 && constraints.maxHeight > 500) {
              return PopScope(
                  canPop: willPop,
                  onPopInvokedWithResult: (result,_){
                    if (notificationModel.hasSecondScreen == true && notificationModel.secondScreenEnable == true) {
                      reInitSecondDisplay(isWillPop: true);
                    }
                    willPop = result;
                  },
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
                    child: AlertDialog(
                      title: Row(
                        children: [
                          Text(AppLocalizations.of(context)!.translate('payment_detail')),
                          SizedBox(
                            width: 20,
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: isButtonDisable
                                ? null
                                : () {
                                    setState(() {
                                      if (notificationModel.hasSecondScreen == true && notificationModel.secondScreenEnable == true) {
                                        reInitSecondDisplay(isWillPop: true);
                                      }
                                      willPop = true;
                                      Navigator.of(context).pop();
                                    });
                                  },
                            color: Colors.red,
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                      content: Container(
                          width: double.maxFinite,
                          child: Row(
                            children: [
                              Expanded(
                                  child: Card(
                                    elevation: 5,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(20),
                                          alignment: Alignment.center,
                                          child: Text(_appSettingModel.table_order == 0
                                              ? AppLocalizations.of(context)!.translate('order_no') + ': ${getOrderNumber(cart, appSettingModel)}'
                                              : _appSettingModel.table_order == 2
                                              ? AppLocalizations.of(context)!.translate('table_no') + ': ${getSelectedCustomTable(cart, appSettingModel)}'
                                              : AppLocalizations.of(context)!.translate('table_no') + ': ${getSelectedTable()}',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                                        ),
                                        Divider(
                                          color: Colors.grey,
                                          height: 1,
                                          thickness: 1,
                                          indent: 20,
                                          endIndent: 20,
                                        ),
                                        Expanded(
                                            child: ListView.builder(
                                                padding: EdgeInsets.only(top: 10),
                                                shrinkWrap: true,
                                                itemCount: itemList.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                    hoverColor: Colors.transparent,
                                                    onTap: null,
                                                    isThreeLine: true,
                                                    title: RichText(
                                                      text: TextSpan(
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                            text: '${itemList[index].product_name!} (${itemList[index].price!}/${itemList[index].per_quantity_unit!}${itemList[index].unit! == 'each' || itemList[index].unit! == 'each_c' ? 'each' : itemList[index].unit!})\n',
                                                            style: TextStyle(
                                                              fontSize: MediaQuery.of(context).size.height > 500 ? 20 : 15,
                                                              color: color.backgroundColor,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                              text: "${currency_symbol}" + getItemTotalPrice(productItem: itemList[index]),
                                                              style: TextStyle(fontSize: 15, color: color.backgroundColor)),
                                                        ],
                                                      ),
                                                    ),
                                                    subtitle: Text(getVariant(itemList[index]) +
                                                        getModifier(itemList[index]) +
                                                        getRemark(itemList[index]),
                                                        style: TextStyle(fontSize: 12)),
                                                    trailing: Container(
                                                      child: FittedBox(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              'x${itemList[index].quantity.toString()}',
                                                              style: TextStyle(
                                                                  color: color.backgroundColor,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 20),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                        ),
                                        SizedBox(height: 10),
                                        Divider(
                                          color: Colors.grey,
                                          height: 1,
                                          thickness: 1,
                                          indent: 20,
                                          endIndent: 20,
                                        ),
                                        SizedBox(height: 10),
                                        Container(
                                          constraints: new BoxConstraints(
                                              maxHeight: MediaQuery.of(context).size.height < 500 && cart.selectedOption == 'Dine in'
                                                  ? 31
                                                  : MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Dine in'
                                                  ? 190
                                                  : 200),
                                          child: ListView(
                                            controller: _controller,
                                            padding: EdgeInsets.only(left: 5, right: 5),
                                            physics: ClampingScrollPhysics(),
                                            children: [
                                              ListTile(
                                                title: Text('Subtotal', style: TextStyle(fontSize: 14)),
                                                trailing: Text('${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                visualDensity: VisualDensity(vertical: -4),
                                                dense: true,
                                              ),
                                              Visibility(
                                                visible: hasSelectedPromo
                                                    ? true
                                                    : false,
                                                child: ListTile(
                                                  title: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Row(
                                                      children: [
                                                        Text('${allPromo} (${selectedPromoRate})',
                                                            style: TextStyle(fontSize: 14)),
                                                      ],
                                                    ),
                                                  ),
                                                  trailing: Text('-${selectedPromo.toStringAsFixed(2)}',
                                                      style: TextStyle(fontSize: 14)),
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  dense: true,
                                                ),
                                              ),
                                              Visibility(
                                                  visible: hasPromo,
                                                  child: ListView.builder(
                                                      physics: NeverScrollableScrollPhysics(),
                                                      padding: EdgeInsets.zero,
                                                      shrinkWrap: true,
                                                      itemCount: autoApplyPromotionList.length,
                                                      itemBuilder: (context, index) {
                                                        return ListTile(
                                                            title: Text('${autoApplyPromotionList[index].name} (${autoApplyPromotionList[index].promoRate})',
                                                                style: TextStyle(fontSize: 14)),
                                                            visualDensity: VisualDensity(vertical: -4),
                                                            dense: true,
                                                            trailing: Text('-${autoApplyPromotionList[index].promoAmount!.toStringAsFixed(2)}',
                                                                style: TextStyle(fontSize: 14)));
                                                      })),
                                              ListView.builder(
                                                  shrinkWrap: true,
                                                  padding: EdgeInsets.zero,
                                                  physics: NeverScrollableScrollPhysics(),
                                                  itemCount: taxList.length,
                                                  itemBuilder: (context, index) {
                                                    return ListTile(
                                                      title: Text('${taxList[index].name}(${taxList[index].tax_rate}%)'),
                                                      trailing: Text('${taxList[index].tax_amount?.toStringAsFixed(2)}'),
                                                      //Text(''),
                                                      visualDensity: VisualDensity(vertical: -4),
                                                      dense: true,
                                                    );
                                                  }),
                                              ListTile(
                                                title: Text('Total',
                                                    style: TextStyle(fontSize: 14)),
                                                trailing: Text('${totalAmount.toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 14)),
                                                visualDensity: VisualDensity(vertical: -4),
                                                dense: true,
                                              ),
                                              ListTile(
                                                title: Text('Rounding',
                                                    style: TextStyle(fontSize: 14)),
                                                trailing: Text(
                                                    '${rounding.toStringAsFixed(2)}',
                                                    style: TextStyle(fontSize: 14)),
                                                visualDensity: VisualDensity(vertical: -4),
                                                dense: true,
                                              ),
                                              for (int index = 0; index < paymentSplitList.length; index++)
                                                ListTile(
                                                  title: Text('${paymentSplitList[index].payment_name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  dense: true,
                                                  trailing: Text('${paymentSplitList[index].payment_received!}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                ),
                                              ListTile(
                                                visualDensity: VisualDensity(vertical: -4),
                                                title: Text('Final Amount',
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                trailing: Text(
                                                    "${finalAmount}",
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                dense: true,
                                              ),
                                            ],
                                            shrinkWrap: true,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Divider(
                                          color: Colors.grey,
                                          height: 1,
                                          thickness: 1,
                                          indent: 20,
                                          endIndent: 20,
                                        ),
                                        SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                              ),
                              //divider
                              Container(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                height:
                                    MediaQuery.of(context).size.height / 2,
                                child: VerticalDivider(
                                    color: Colors.grey, thickness: 1),
                              ),
                              Expanded(
                                child: _type == 0
                                      ? Container(
                                  /// cash
                                          margin: EdgeInsets.fromLTRB(30, 0, 25, 0),
                                          //height: MediaQuery.of(context).size.height / 1,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                child: Text('$currency_symbol${finalAmount}',
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              Container(
                                                margin:
                                                    EdgeInsets.only(bottom: 10),
                                                alignment: Alignment.centerLeft,
                                                child:
                                                    Text('Change: ${change}'),
                                              ),
                                              Container(
                                                margin: EdgeInsets.only(bottom: 10),
                                                child: ValueListenableBuilder(
                                                    valueListenable: inputController,
                                                    builder: (context, TextEditingValue value, __) {
                                                      return Container(
                                                        child: TextField(
                                                          onSubmitted: (value) {
                                                            makePayment();
                                                          },
                                                          onChanged: (value) {
                                                            calcChange(value);
                                                          },
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                                                          ],
                                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                          textAlign: TextAlign.right,
                                                          maxLines: 1,
                                                          controller: inputController,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: color.backgroundColor)),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderSide: BorderSide(color: color.backgroundColor),
                                                            ),
                                                          ),
                                                          style: TextStyle(
                                                              fontSize: 40),
                                                        ),
                                                      );
                                                    }),
                                              ),
                                              //cash chips
                                              Container(
                                                  child: Wrap(
                                                      runSpacing: 5,
                                                      spacing: 10,
                                                      children: [
                                                    ChoiceChip(
                                                      label: Text('$currency_symbol $finalAmount'),
                                                      selected: chipSelected,
                                                      elevation: 5,
                                                      onSelected: (chipSelected) {
                                                        inputController.text = finalAmount;
                                                        calcChange(inputController.text);
                                                      },
                                                    ),
                                                    ChoiceChip(
                                                      label: Text('$currency_symbol 10.00'),
                                                      selected: chipSelected,
                                                      elevation: 5,
                                                      onSelected: (chipSelected) {
                                                        inputController.text = '10.00';
                                                        calcChange(inputController.text);
                                                      },
                                                    ),
                                                    ChoiceChip(
                                                      label: Text('$currency_symbol 20.00'),
                                                      selected: chipSelected,
                                                      elevation: 5,
                                                      onSelected: (chipSelected) {
                                                        inputController.text = '20.00';
                                                        calcChange(inputController.text);
                                                      },
                                                    ),
                                                    ChoiceChip(
                                                      label: Text('$currency_symbol 50.00'),
                                                      selected: chipSelected,
                                                      elevation: 5,
                                                      onSelected: (chipSelected) {
                                                        inputController.text = '50.00';
                                                        calcChange(inputController.text);
                                                      },
                                                    ),
                                                    ChoiceChip(
                                                      label: Text('$currency_symbol 100.00'),
                                                      selected: chipSelected,
                                                      elevation: 5,
                                                      onSelected: (chipSelected) {
                                                        inputController.text = '100.00';
                                                        calcChange(inputController.text);
                                                      },
                                                    ),
                                                  ])),
                                              Container(
                                                margin: EdgeInsets.only(top: 10),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height: 70,
                                                      width: 150,
                                                      child: ElevatedButton.icon(
                                                          onPressed: isButtonDisable || itemList.isEmpty ? null : () async => makePayment(),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: color.backgroundColor,
                                                            elevation: 5,
                                                          ),
                                                          icon: Icon(Icons.payments, size: 24),
                                                          label: Text(
                                                            AppLocalizations.of(context)!.translate('make_payment'),
                                                            style: TextStyle(fontSize: 20),
                                                          ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    SizedBox(
                                                      height: 70,
                                                      width: 150,
                                                      child: ElevatedButton.icon(
                                                        onPressed: () async {
                                                          inputController.clear();
                                                          change = '0.00';
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          elevation: 5,
                                                          backgroundColor: color.buttonColor,
                                                        ),
                                                        icon: Icon(Icons.backspace),
                                                        label: Text(AppLocalizations.of(context)!.translate('clear'),
                                                            style: TextStyle(fontSize: 20)),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    SizedBox(
                                                      height: 70,
                                                      width: 150,
                                                      child:
                                                      ElevatedButton.icon(
                                                          onPressed: () async {
                                                            split_payment = !split_payment;
                                                            paymentSplitDialog = true;
                                                            splitAmountController.clear();
                                                            if(!split_payment) {
                                                              paymentSplitDialog = false;
                                                            }

                                                            splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                              context: context,
                                                              builder: (BuildContext context) {
                                                                return AlertDialog(
                                                                  title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                                  content: SizedBox(
                                                                    height: 75.0,
                                                                    width: 350.0,
                                                                    child: ValueListenableBuilder(
                                                                      valueListenable: splitAmountController,
                                                                      builder: (context, TextEditingValue value, __) {
                                                                        return Padding(
                                                                          padding: const EdgeInsets.all(8.0),
                                                                          child: TextField(
                                                                            autofocus: true,
                                                                            onSubmitted: (input) {
                                                                              if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                                  double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                                finalAmount = splitAmountController.text;
                                                                                setState(() {
                                                                                  isButtonDisabled = true;
                                                                                  willPop = false;
                                                                                  Navigator.of(context).pop();
                                                                                });
                                                                              } else {
                                                                                Fluttertoast.showToast(
                                                                                    backgroundColor: Color(0xFFFF0000),
                                                                                    msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                                splitAmountController.clear();
                                                                              }
                                                                            },
                                                                            controller: splitAmountController,
                                                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                            decoration: InputDecoration(
                                                                              border: OutlineInputBorder(
                                                                                borderSide: BorderSide(color: color.backgroundColor),
                                                                              ),
                                                                              focusedBorder: OutlineInputBorder(
                                                                                borderSide: BorderSide(color: color.backgroundColor),
                                                                              ),
                                                                              labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                  actions: <Widget>[
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          flex: 1,
                                                                          child: SizedBox(
                                                                            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                                                                                setState(() {
                                                                                  isButtonDisabled = true;
                                                                                  splitAmountController.clear();
                                                                                  split_payment = !split_payment;
                                                                                });
                                                                                Navigator.of(context).pop();
                                                                                if (mounted) {
                                                                                  setState(() {
                                                                                    isButtonDisabled = false;
                                                                                  });
                                                                                }
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(width: 10),
                                                                        Expanded(
                                                                          flex: 1,
                                                                          child: SizedBox(
                                                                            width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                            height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                                                                            child: ElevatedButton(
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: color.buttonColor,
                                                                              ),
                                                                              child: Text(
                                                                                AppLocalizations.of(context)!.translate('yes'),
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                              onPressed: isButtonDisabled
                                                                                  ? null
                                                                                  : () async {
                                                                                if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                                    double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                                  finalAmount = splitAmountController.text;
                                                                                  setState(() {
                                                                                    isButtonDisabled = true;
                                                                                    willPop = false;
                                                                                    Navigator.of(context).pop();
                                                                                  });
                                                                                } else {
                                                                                  Fluttertoast.showToast(
                                                                                      backgroundColor: Color(0xFFFF0000),
                                                                                      msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                                  splitAmountController.clear();
                                                                                }
                                                                              },
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ).then((_) {
                                                              if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                                setState(() {
                                                                  split_payment = false;
                                                                });
                                                              }
                                                            }) : null;
                                                            setState(() {
                                                              isButtonDisabled = false;
                                                            });
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.blue,
                                                            elevation: 5,
                                                          ),
                                                          icon: Icon(Icons.payments_outlined, size: 24),
                                                          label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                              : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                            style: TextStyle(fontSize: 20),
                                                          )),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Visibility(
                                                visible: split_payment,
                                                child: isload ? Container(
                                                  padding: EdgeInsets.only(top: 20),
                                                  height: 100,
                                                  child: Center(
                                                    child: ListView(
                                                        shrinkWrap: true,
                                                        // crossAxisCount: 5,
                                                        scrollDirection: Axis.horizontal,
                                                        children: List.generate(PaymentLists.length, (index) {
                                                          return GestureDetector(
                                                            onTap: () async {
                                                              setState(() {
                                                                _type = PaymentLists[index].type!;
                                                                order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                              });
                                                            },
                                                            child: Card(
                                                              elevation: 5,
                                                              color: Colors.white,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(16.0),
                                                              ),
                                                              child: Container(
                                                                height: MediaQuery.of(context).size.height / 4,
                                                                width: 100,
                                                                child: Stack(
                                                                  alignment: Alignment.center,
                                                                  children: [
                                                                    Text(
                                                                      '${PaymentLists[index].name}',
                                                                      textAlign: TextAlign.center,
                                                                      overflow: TextOverflow.clip,
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.w700,
                                                                        fontStyle: FontStyle.normal,
                                                                        fontSize: 15,
                                                                        color: Colors.blueGrey,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                    ),
                                                  ),
                                                )
                                                    : CustomProgressBar(),
                                              )
                                            ],
                                          ), // GridView.builder
                                        )
                                      : _type == 1 ?
                                          /// card, ewallet
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16.0),
                                                  child:
                                                      ///***If you have exported images you must have to copy those images in assets/images directory.
                                                      Image(image: AssetImage("drawable/duitNow.jpg")),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.all(20),
                                                child: Text('$currency_symbol${finalAmount}',
                                                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Container(
                                                child: ElevatedButton.icon(
                                                  style: ButtonStyle(
                                                      backgroundColor: MaterialStateProperty.all(Colors.green),
                                                      padding: MaterialStateProperty.all(EdgeInsets.all(20))),
                                                  onPressed: isButtonDisable || itemList.isEmpty ? null : () async {
                                                    setState(() {
                                                      willPop = false;
                                                      isButtonDisable = true;
                                                    });
                                                    asyncQ.addJob((_) async {
                                                      try{
                                                        await callCreateOrder(finalAmount);
                                                        // await callCreateOrder(finalAmount);

                                                        if (this.isLogOut == true) {
                                                          openLogOutDialog();
                                                          return;
                                                        }
                                                        await openPaymentSuccessDialog(widget.dining_id, split_payment, isCashMethod: false, diningName: widget.dining_name);
                                                        Branch? data = await PosDatabase.instance.readLocalBranch();
                                                        if(data != null && data.allow_livedata == 1){
                                                          if(!isSyncisSyncingingNotifier.value){
                                                            isSyncisSyncingingNotifier.value = true;
                                                            do{
                                                              await syncToCloud.syncAllToCloud(isManualSync: true);
                                                            }while(syncToCloud.emptyResponse == false);
                                                            if(syncToCloud.emptyResponse == true){
                                                              isSyncisSyncingingNotifier.value = false;
                                                            }
                                                          }
                                                        }
                                                      }catch(e){
                                                        print("error: $e");
                                                      }
                                                    });
                                                  },
                                                  icon: Icon(Icons.call_received),
                                                  label: Text(
                                                      AppLocalizations.of(context)!.translate('payment_received'),
                                                      style: TextStyle(fontSize: 20)),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                child: ElevatedButton.icon(
                                                  style: ButtonStyle(
                                                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                                                      padding: MaterialStateProperty.all(EdgeInsets.all(20))),
                                                  onPressed: () async {
                                                    split_payment = !split_payment;
                                                    paymentSplitDialog = true;
                                                    splitAmountController.clear();
                                                    if(!split_payment) {
                                                      paymentSplitDialog = false;
                                                    }

                                                    splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                          content: SizedBox(
                                                            height: 75.0,
                                                            width: 350.0,
                                                            child: ValueListenableBuilder(
                                                              valueListenable: splitAmountController,
                                                              builder: (context, TextEditingValue value, __) {
                                                                return Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child: TextField(
                                                                    autofocus: true,
                                                                    onSubmitted: (input) {
                                                                      if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                          double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                        finalAmount = splitAmountController.text;
                                                                        setState(() {
                                                                          isButtonDisabled = true;
                                                                          willPop = false;
                                                                          Navigator.of(context).pop();
                                                                        });
                                                                      } else {
                                                                        Fluttertoast.showToast(
                                                                            backgroundColor: Color(0xFFFF0000),
                                                                            msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                        splitAmountController.clear();
                                                                      }
                                                                    },
                                                                    controller: splitAmountController,
                                                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                    decoration: InputDecoration(
                                                                      border: OutlineInputBorder(
                                                                        borderSide: BorderSide(color: color.backgroundColor),
                                                                      ),
                                                                      focusedBorder: OutlineInputBorder(
                                                                        borderSide: BorderSide(color: color.backgroundColor),
                                                                      ),
                                                                      labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          actions: <Widget>[
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  flex: 1,
                                                                  child: SizedBox(
                                                                    width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                    height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                                                                        setState(() {
                                                                          isButtonDisabled = true;
                                                                          splitAmountController.clear();
                                                                          split_payment = !split_payment;
                                                                        });
                                                                        Navigator.of(context).pop();
                                                                        if (mounted) {
                                                                          setState(() {
                                                                            isButtonDisabled = false;
                                                                          });
                                                                        }
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(width: 10),
                                                                Expanded(
                                                                  flex: 1,
                                                                  child: SizedBox(
                                                                    width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                    height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                                                                    child: ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: color.buttonColor,
                                                                      ),
                                                                      child: Text(
                                                                        AppLocalizations.of(context)!.translate('yes'),
                                                                        style: TextStyle(color: Colors.white),
                                                                      ),
                                                                      onPressed: isButtonDisabled
                                                                          ? null
                                                                          : () async {
                                                                        if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                            double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                          finalAmount = splitAmountController.text;
                                                                          setState(() {
                                                                            isButtonDisabled = true;
                                                                            willPop = false;
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        } else {
                                                                          Fluttertoast.showToast(
                                                                              backgroundColor: Color(0xFFFF0000),
                                                                              msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                          splitAmountController.clear();
                                                                        }
                                                                      },
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            )
                                                          ],
                                                        );
                                                      },
                                                    ).then((_) {
                                                      if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                        setState(() {
                                                          split_payment = false;
                                                        });
                                                      }
                                                    }) : null;
                                                    setState(() {
                                                    isButtonDisabled = false;
                                                    });
                                                  },
                                                  icon: Icon(Icons.payments_outlined),
                                                  label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                          : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                      style: TextStyle(fontSize: 20)
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible: split_payment,
                                                child: isload ? Container(
                                                  padding: EdgeInsets.only(top: 20),
                                                  height: 100,
                                                  child: Center(
                                                    child: ListView(
                                                        shrinkWrap: true,
                                                        // crossAxisCount: 5,
                                                        scrollDirection: Axis.horizontal,
                                                        children: List.generate(PaymentLists.length, (index) {
                                                          return GestureDetector(
                                                            onTap: () async {
                                                              setState(() {
                                                                _type = PaymentLists[index].type!;
                                                                order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                              });
                                                            },
                                                            child: Card(
                                                              elevation: 5,
                                                              color: Colors.white,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(16.0),
                                                              ),
                                                              child: Container(
                                                                height: MediaQuery.of(context).size.height / 4,
                                                                width: 100,
                                                                child: Stack(
                                                                  alignment: Alignment.center,
                                                                  children: [
                                                                    Text(
                                                                      '${PaymentLists[index].name}',
                                                                      textAlign: TextAlign.center,
                                                                      overflow: TextOverflow.clip,
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.w700,
                                                                        fontStyle: FontStyle.normal,
                                                                        fontSize: 15,
                                                                        color: Colors.blueGrey,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                    ),
                                                  ),
                                                )
                                                : CustomProgressBar(),
                                              )
                                            ],
                                          )
                                          : _type == 2
                                /// qr scan
                                              ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.all(25),
                                                    child: scanning == false ?
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(0.0),
                                                      child: Image(
                                                        image: AssetImage("drawable/TNG.jpg"),
                                                        // FileImage(File(
                                                        //     'data/user/0/com.example.pos_system/files/assets/img/TNG.jpg')),
                                                        height: 250,
                                                        width: 250,
                                                      ),
                                                    ) :
                                                    Container(
                                                      height: 250,
                                                      width: 250,
                                                      // margin: EdgeInsets.all(25),
                                                      child: _buildQrView(context),
                                                    ),
                                                  ),
                                                  Container(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                        '$currency_symbol${finalAmount}',
                                                        style: TextStyle(
                                                            fontSize: 40,
                                                            fontWeight: FontWeight.bold)),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor, padding: EdgeInsets.fromLTRB(20, 14, 20, 14)),
                                                        onPressed: () async {
                                                          setState(() {
                                                            willPop = false;
                                                            scanning = !scanning;
                                                          });
                                                          //await controller?.resumeCamera();
                                                          await controller?.scannedDataStream;
                                                          // await callCreateOrder(finalAmount);
                                                          if (this.isLogOut == true) {
                                                            openLogOutDialog();
                                                            return;
                                                          }
                                                        },
                                                        icon: Icon(Icons.qr_code_scanner, size: 24),
                                                        label: Text(
                                                            scanning == false ?
                                                            AppLocalizations.of(context)!.translate('scan_qr') :
                                                            AppLocalizations.of(context)!.translate('cancel'),
                                                            style: TextStyle(fontSize: 24)),
                                                      ),
                                                      SizedBox(width: 10),
                                                      ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: EdgeInsets.fromLTRB(20, 14, 20, 14)),
                                                        onPressed: () async {
                                                          split_payment = !split_payment;
                                                          paymentSplitDialog = true;
                                                          splitAmountController.clear();
                                                          if(!split_payment) {
                                                            paymentSplitDialog = false;
                                                          }

                                                          splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                                content: SizedBox(
                                                                  height: 75.0,
                                                                  width: 350.0,
                                                                  child: ValueListenableBuilder(
                                                                    valueListenable: splitAmountController,
                                                                    builder: (context, TextEditingValue value, __) {
                                                                      return Padding(
                                                                        padding: const EdgeInsets.all(8.0),
                                                                        child: TextField(
                                                                          autofocus: true,
                                                                          onSubmitted: (input) {
                                                                            if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                                double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                              finalAmount = splitAmountController.text;
                                                                              setState(() {
                                                                                isButtonDisabled = true;
                                                                                willPop = false;
                                                                                Navigator.of(context).pop();
                                                                              });
                                                                            } else {
                                                                              Fluttertoast.showToast(
                                                                                  backgroundColor: Color(0xFFFF0000),
                                                                                  msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                              splitAmountController.clear();
                                                                            }
                                                                          },
                                                                          controller: splitAmountController,
                                                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                          decoration: InputDecoration(
                                                                            border: OutlineInputBorder(
                                                                              borderSide: BorderSide(color: color.backgroundColor),
                                                                            ),
                                                                            focusedBorder: OutlineInputBorder(
                                                                              borderSide: BorderSide(color: color.backgroundColor),
                                                                            ),
                                                                            labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                actions: <Widget>[
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child: SizedBox(
                                                                          width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                          height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                                                                              setState(() {
                                                                                isButtonDisabled = true;
                                                                                splitAmountController.clear();
                                                                                split_payment = !split_payment;
                                                                              });
                                                                              Navigator.of(context).pop();
                                                                              if (mounted) {
                                                                                setState(() {
                                                                                  isButtonDisabled = false;
                                                                                });
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(width: 10),
                                                                      Expanded(
                                                                        flex: 1,
                                                                        child: SizedBox(
                                                                          width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                          height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                                                                          child: ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: color.buttonColor,
                                                                            ),
                                                                            child: Text(
                                                                              AppLocalizations.of(context)!.translate('yes'),
                                                                              style: TextStyle(color: Colors.white),
                                                                            ),
                                                                            onPressed: isButtonDisabled
                                                                                ? null
                                                                                : () async {
                                                                              if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                                  double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                                finalAmount = splitAmountController.text;
                                                                                setState(() {
                                                                                  isButtonDisabled = true;
                                                                                  willPop = false;
                                                                                  Navigator.of(context).pop();
                                                                                });
                                                                              } else {
                                                                                Fluttertoast.showToast(
                                                                                    backgroundColor: Color(0xFFFF0000),
                                                                                    msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                                splitAmountController.clear();
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  )
                                                                ],
                                                              );
                                                            },
                                                          ).then((_) {
                                                            if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                              setState(() {
                                                                split_payment = false;
                                                              });
                                                            }
                                                          }) : null;
                                                          setState(() {
                                                            isButtonDisabled = false;
                                                          });
                                                        },
                                                        icon: Icon(Icons.payments_outlined, size: 24),
                                                        label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                            : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                            style: TextStyle(fontSize: 24)),
                                                      ),
                                                    ],
                                                  ),
                                                  Visibility(
                                                    visible: split_payment,
                                                    child: isload ? Container(
                                                      margin: EdgeInsets.only(top: 20),
                                                      height: 100,
                                                      child: Center(
                                                        child: ListView(
                                                            shrinkWrap: true,
                                                            // crossAxisCount: 5,
                                                            scrollDirection: Axis.horizontal,
                                                            children: List.generate(PaymentLists.length, (index) {
                                                              return GestureDetector(
                                                                onTap: () async {
                                                                  setState(() {
                                                                    _type = PaymentLists[index].type!;
                                                                    order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                                  });
                                                                },
                                                                child: Card(
                                                                  elevation: 5,
                                                                  color: Colors.white,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(16.0),
                                                                  ),
                                                                  child: Container(
                                                                    height: MediaQuery.of(context).size.height / 4,
                                                                    width: 100,
                                                                    child: Stack(
                                                                      alignment: Alignment.center,
                                                                      children: [
                                                                        Text(
                                                                          '${PaymentLists[index].name}',
                                                                          textAlign: TextAlign.center,
                                                                          overflow: TextOverflow.clip,
                                                                          style: TextStyle(
                                                                            fontWeight: FontWeight.w700,
                                                                            fontStyle: FontStyle.normal,
                                                                            fontSize: 15,
                                                                            color: Colors.blueGrey,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            })
                                                        ),
                                                      ),
                                                    )
                                                        : CustomProgressBar(),
                                                  )
                                                ],
                                              )
                                              : Container(),
                              )
                            ],
                          )),
                    ),
                  ));
            } else {
              ///mobile layout
              return Center(
                child: SingleChildScrollView(
                  // physics: NeverScrollableScrollPhysics(),
                  child: AlertDialog(
                    titlePadding: EdgeInsets.fromLTRB(15, 5, 15, 0),
                    contentPadding:
                        EdgeInsets.only(left: 15, right: 15, bottom: 10),
                    // insetPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Text(AppLocalizations.of(context)!.translate('payment_detail')),
                        Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: isButtonDisable ? null : () {
                            setState(() {
                              if (notificationModel.hasSecondScreen == true && notificationModel.secondScreenEnable == true) {
                                reInitSecondDisplay(isWillPop: true);
                              }
                              willPop = true;
                              Navigator.of(context).pop();
                            });
                            },
                          color: Colors.red,
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    content: Container(
                        // width: MediaQuery.of(context).size.width / 1.2,
                        height: MediaQuery.of(context).size.height / 1.5,
                        width: 650,
                        // height: 250,
                        child: MediaQuery.of(context).orientation == Orientation.landscape ? Row(
                          children: [
                            Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                            _appSettingModel.table_order == 0 ? AppLocalizations.of(context)!.translate('order_no') + ': ${getOrderNumber(cart, appSettingModel)}'
                                                : AppLocalizations.of(context)!.translate('table_no') + ': ${getSelectedTable()}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20)),
                                      ),
                                      Container(
                                        //margin: EdgeInsets.all(25),
                                        child: Card(
                                          elevation: 5,
                                          child: Column(
                                            children: [
                                              ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: NeverScrollableScrollPhysics(),
                                                  itemCount: itemList.length,
                                                  padding: EdgeInsets.only(top: 10),
                                                  itemBuilder: (context, index) {
                                                    return ListTile(
                                                      onTap: null,
                                                      isThreeLine: true,
                                                      title: RichText(
                                                        text: TextSpan(
                                                          children: <TextSpan>[
                                                            TextSpan(
                                                              text: '${itemList[index].product_name!} (${itemList[index].price!}/${itemList[index].per_quantity_unit!}${itemList[index].unit! == 'each' || itemList[index].unit! == 'each_c' ? 'each' : itemList[index].unit!})\n',
                                                              style: TextStyle(
                                                                  fontSize: 15,
                                                                  color: color.backgroundColor,
                                                                  fontWeight: FontWeight.bold),
                                                            ),
                                                            TextSpan(
                                                                text: "${currency_symbol}" + itemList[index].price!,
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  color: color.backgroundColor,
                                                                )),
                                                          ],
                                                        ),
                                                      ),
                                                      subtitle: Text(getVariant(itemList[index]) +
                                                          getModifier(itemList[index]) +
                                                          getRemark(itemList[index]),
                                                      style: TextStyle(fontSize: 12)),
                                                  trailing: Container(
                                                    child: FittedBox(
                                                      child: Row(
                                                        children: [
                                                          Text('x${itemList[index].quantity.toString()}',
                                                            style: TextStyle(
                                                                color: color.backgroundColor,
                                                                fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                          SizedBox(height: 5),
                                          Divider(
                                            color: Colors.grey,
                                            height: 1,
                                            thickness: 1,
                                            indent: 20,
                                            endIndent: 20,
                                          ),
                                          SizedBox(height: 5),
                                          Container(
                                            constraints: new BoxConstraints(
                                                maxHeight: MediaQuery.of(context).size.height / 2),
                                            // height: MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Dine in' ? 190
                                            //         : MediaQuery.of(context).size.height < 700 && cart.selectedOption == 'Take Away' ? 180
                                            //         : 200,
                                            child: ListView(
                                              controller: _controller,
                                              padding: EdgeInsets.only(
                                                  left: 5, right: 5),
                                              physics: ClampingScrollPhysics(),
                                              children: [
                                                ListTile(
                                                  title: Text('Subtotal', style: TextStyle(fontSize: 14)),
                                                  trailing: Text('${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  dense: true,
                                                ),
                                                Visibility(
                                                  visible: hasSelectedPromo
                                                      ? true
                                                      : false,
                                                  child: ListTile(
                                                    title: SingleChildScrollView(
                                                      scrollDirection: Axis.horizontal,
                                                      child: Row(
                                                        children: [
                                                          Text('${allPromo} (${selectedPromoRate})', style: TextStyle(fontSize: 14)),
                                                        ],
                                                      ),
                                                    ),
                                                    trailing: Text('-${selectedPromo.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                  ),
                                                ),
                                                Visibility(
                                                    visible: hasPromo == true ? true : false,
                                                    child: ListView.builder(
                                                        physics: NeverScrollableScrollPhysics(),
                                                        padding: EdgeInsets.zero,
                                                        shrinkWrap: true,
                                                        itemCount: autoApplyPromotionList.length,
                                                        itemBuilder: (context, index) {
                                                          return ListTile(
                                                              title: Text('${autoApplyPromotionList[index].name} (${autoApplyPromotionList[index].promoRate})',
                                                                  style: TextStyle(fontSize: 14)),
                                                              visualDensity: VisualDensity(vertical: -4),
                                                              dense: true,
                                                              trailing: Text('-${autoApplyPromotionList[index].promoAmount!.toStringAsFixed(2)}',
                                                                  style: TextStyle(fontSize: 14)));
                                                        })),
                                                ListView.builder(
                                                    shrinkWrap: true,
                                                    padding: EdgeInsets.zero,
                                                    physics: NeverScrollableScrollPhysics(),
                                                    itemCount: taxList.length,
                                                    itemBuilder: (context, index) {
                                                      return ListTile(
                                                        title: Text('${taxList[index].name}(${taxList[index].tax_rate}%)'),
                                                        trailing: Text('${taxList[index].tax_amount?.toStringAsFixed(2)}'),
                                                        visualDensity: VisualDensity(vertical: -4),
                                                        dense: true,
                                                      );
                                                    }),
                                                ListTile(
                                                  title: Text('Total', style: TextStyle(fontSize: 14)),
                                                  trailing: Text('${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  dense: true,
                                                ),
                                                ListTile(
                                                  title: Text('Rounding',
                                                      style: TextStyle(fontSize: 14)),
                                                  trailing: Text(
                                                      '${rounding.toStringAsFixed(2)}',
                                                      style: TextStyle(fontSize: 14)),
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  dense: true,
                                                ),
                                                for (int index = 0; index < paymentSplitList.length; index++)
                                                  ListTile(
                                                    title: Text('${paymentSplitList[index].payment_name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                    trailing: Text('${paymentSplitList[index].payment_received!}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                  ),
                                                ListTile(
                                                  visualDensity: VisualDensity(vertical: -4),
                                                  title: Text('Final Amount',
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                  trailing: Text("${finalAmount}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                  dense: true,
                                                ),
                                              ],
                                              shrinkWrap: true,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Divider(
                                            color: Colors.grey,
                                            height: 1,
                                            thickness: 1,
                                            indent: 20,
                                            endIndent: 20,
                                          ),
                                          SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            Container(
                              margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                              height: 200,
                              child: VerticalDivider(
                                  color: Colors.grey, thickness: 1),
                            ),
                            Expanded(
                              child: _type == 0
                              /// cash
                                  ? SingleChildScrollView(
                                    child: Container(
                                      height: split_payment ? 350 : 250,
                                      child: Column(
                                        children: [
                                      Text("Total: ${finalAmount}",
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        alignment: Alignment.centerLeft,
                                        child: Text('Change: ${change}'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                  bottom: 10),
                                              child: ValueListenableBuilder(
                                                  valueListenable: inputController,
                                                  builder: (context, TextEditingValue value, __) {
                                                    return Container(
                                                      child: TextField(
                                                        onChanged: (value) {
                                                          calcChange(value);
                                                        },
                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                        textAlign: TextAlign.right,
                                                        enabled: MediaQuery.of(context).size.height > 500 ? false : true,
                                                        maxLines: 1,
                                                        controller: inputController,
                                                        decoration: InputDecoration(
                                                          border: OutlineInputBorder(
                                                              borderSide: BorderSide(color: color.backgroundColor)),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: color.backgroundColor),
                                                          ),
                                                        ),
                                                        style: TextStyle(fontSize: 30),
                                                      ),
                                                    );
                                                  }),
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(backgroundColor: color.backgroundColor),
                                                      onPressed: isButtonDisable || itemList.isEmpty ? null : () async => makePayment(),
                                                      icon: Icon(Icons.payments, size: 20),
                                                      label: Text(AppLocalizations.of(context)!.translate('make_payment'))),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                                      onPressed: () {
                                                        inputController.clear();
                                                        setState(() {
                                                          change = '0.00';
                                                        });
                                                      },
                                                      icon: Icon(Icons.backspace, size: 20),
                                                      label: Text(AppLocalizations.of(context)!.translate('clear'))),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                onPressed: () async {
                                                  split_payment = !split_payment;
                                                  paymentSplitDialog = true;
                                                  splitAmountController.clear();
                                                  if(!split_payment) {
                                                    paymentSplitDialog = false;
                                                  }

                                                  splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                        content: SizedBox(
                                                          height: 75.0,
                                                          width: 350.0,
                                                          child: ValueListenableBuilder(
                                                            valueListenable: splitAmountController,
                                                            builder: (context, TextEditingValue value, __) {
                                                              return Padding(
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: TextField(
                                                                  autofocus: true,
                                                                  onSubmitted: (input) {
                                                                    if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                        double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                      finalAmount = splitAmountController.text;
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        willPop = false;
                                                                        Navigator.of(context).pop();
                                                                      });
                                                                    } else {
                                                                      Fluttertoast.showToast(
                                                                          backgroundColor: Color(0xFFFF0000),
                                                                          msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                      splitAmountController.clear();
                                                                    }
                                                                  },
                                                                  controller: splitAmountController,
                                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                  decoration: InputDecoration(
                                                                    border: OutlineInputBorder(
                                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                                    ),
                                                                    focusedBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                                    ),
                                                                    labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 1,
                                                                child: SizedBox(
                                                                  width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                  height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        splitAmountController.clear();
                                                                        split_payment = !split_payment;
                                                                      });
                                                                      Navigator.of(context).pop();
                                                                      if (mounted) {
                                                                        setState(() {
                                                                          isButtonDisabled = false;
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(width: 10),
                                                              Expanded(
                                                                flex: 1,
                                                                child: SizedBox(
                                                                  width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                  height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                                                                  child: ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: color.buttonColor,
                                                                    ),
                                                                    child: Text(
                                                                      AppLocalizations.of(context)!.translate('yes'),
                                                                      style: TextStyle(color: Colors.white),
                                                                    ),
                                                                    onPressed: isButtonDisabled
                                                                        ? null
                                                                        : () async {
                                                                      if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                          double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                        finalAmount = splitAmountController.text;
                                                                        setState(() {
                                                                          isButtonDisabled = true;
                                                                          willPop = false;
                                                                          Navigator.of(context).pop();
                                                                        });
                                                                      } else {
                                                                        Fluttertoast.showToast(
                                                                            backgroundColor: Color(0xFFFF0000),
                                                                            msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                        splitAmountController.clear();
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      );
                                                    },
                                                  ).then((_) {
                                                    if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                      setState(() {
                                                        split_payment = false;
                                                      });
                                                    }
                                                  }) : null;
                                                  setState(() {
                                                    isButtonDisabled = false;
                                                  });
                                                },
                                                icon: Icon(Icons.payments_outlined, size: 20),
                                                label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                    : AppLocalizations.of(context)!.translate('split_payment_cancel'))
                                            ),
                                            Visibility(
                                              visible: split_payment,
                                              child: isload ? Container(
                                                padding: EdgeInsets.only(top: 20),
                                                height: 100,
                                                child: Center(
                                                  child: ListView(
                                                      shrinkWrap: true,
                                                      scrollDirection: Axis.horizontal,
                                                      children: List.generate(PaymentLists.length, (index) {
                                                        return GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              _type = PaymentLists[index].type!;
                                                              order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                            });
                                                          },
                                                          child: Card(
                                                            elevation: 5,
                                                            color: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16.0),
                                                            ),
                                                            child: Container(
                                                              height: MediaQuery.of(context).size.height / 4,
                                                              width: 100,
                                                              child: Stack(
                                                                alignment: Alignment.center,
                                                                children: [
                                                                  Text(
                                                                    '${PaymentLists[index].name}',
                                                                    textAlign: TextAlign.center,
                                                                    overflow: TextOverflow.clip,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.w700,
                                                                      fontStyle: FontStyle.normal,
                                                                      fontSize: 15,
                                                                      color: Colors.blueGrey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                  ),
                                                ),
                                              )
                                                  : CustomProgressBar(),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                      ), // GridView.builder
                                    ),
                                  )
                                  : _type == 1
                              /// card, ewallet
                                  ? SingleChildScrollView(
                                    child: Container(
                                      child: Column(
                                        children: [
                                          Text('Total: ${finalAmount}',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            height: 150,
                                            //margin: EdgeInsets.only(bottom: 10),
                                            margin: EdgeInsets.all(10),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16.0),
                                              child:
                                              ///***If you have exported images you must have to copy those images in assets/images directory.
                                              Image(image: AssetImage("drawable/duitNow.jpg")),
                                            ),
                                          ),
                                          Container(
                                            child: ElevatedButton.icon(
                                              style: ButtonStyle(
                                                  backgroundColor: MaterialStateProperty.all(Colors.green),
                                              ),
                                              onPressed: isButtonDisable || itemList.isEmpty ? null : () async {
                                                setState(() {
                                                  // willPop = false;
                                                  isButtonDisable = true;
                                                });
                                                asyncQ.addJob((_) async {
                                                  try{
                                                    await callCreateOrder(finalAmount);
                                                    // await callCreateOrder(finalAmount);
                                                    if (this.isLogOut == true) {
                                                      openLogOutDialog();
                                                      return;
                                                    }
                                                    await openPaymentSuccessDialog(
                                                        widget.dining_id,
                                                        split_payment,
                                                        isCashMethod: false,
                                                        diningName: widget.dining_name);
                                                    Branch? data = await PosDatabase.instance.readLocalBranch();
                                                    if(data != null && data.allow_livedata == 1){
                                                      if(!isSyncisSyncingingNotifier.value){
                                                        isSyncisSyncingingNotifier.value = true;
                                                        do{
                                                          await syncToCloud.syncAllToCloud(isManualSync: true);
                                                        }while(syncToCloud.emptyResponse == false);
                                                        if(syncToCloud.emptyResponse == true){
                                                          isSyncisSyncingingNotifier.value = false;
                                                        }
                                                      }
                                                    }
                                                  }catch(e){
                                                    print("error: $e");
                                                  }
                                                });
                                              },
                                              icon: Icon(Icons.call_received, size: 20),
                                              label: Text(
                                                  AppLocalizations.of(context)!.translate('payment_received'),
                                                  style: TextStyle(fontSize: 14)),
                                            ),
                                          ),
                                          Container(
                                            child: ElevatedButton.icon(
                                              style: ButtonStyle(
                                                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                                              ),
                                              onPressed: () async {
                                                split_payment = !split_payment;
                                                paymentSplitDialog = true;
                                                splitAmountController.clear();
                                                if(!split_payment) {
                                                  paymentSplitDialog = false;
                                                }

                                                splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                      content: SizedBox(
                                                        height: 75.0,
                                                        width: 350.0,
                                                        child: ValueListenableBuilder(
                                                          valueListenable: splitAmountController,
                                                          builder: (context, TextEditingValue value, __) {
                                                            return Padding(
                                                              padding: const EdgeInsets.all(8.0),
                                                              child: TextField(
                                                                autofocus: true,
                                                                onSubmitted: (input) {
                                                                  if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                      double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                    finalAmount = splitAmountController.text;
                                                                    setState(() {
                                                                      isButtonDisabled = true;
                                                                      willPop = false;
                                                                      Navigator.of(context).pop();
                                                                    });
                                                                  } else {
                                                                    Fluttertoast.showToast(
                                                                        backgroundColor: Color(0xFFFF0000),
                                                                        msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                    splitAmountController.clear();
                                                                  }
                                                                },
                                                                controller: splitAmountController,
                                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                decoration: InputDecoration(
                                                                  border: OutlineInputBorder(
                                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                                  ),
                                                                  focusedBorder: OutlineInputBorder(
                                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                                  ),
                                                                  labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                                                                    setState(() {
                                                                      isButtonDisabled = true;
                                                                      splitAmountController.clear();
                                                                      split_payment = !split_payment;
                                                                    });
                                                                    Navigator.of(context).pop();
                                                                    if (mounted) {
                                                                      setState(() {
                                                                        isButtonDisabled = false;
                                                                      });
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                                                                child: ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: color.buttonColor,
                                                                  ),
                                                                  child: Text(
                                                                    AppLocalizations.of(context)!.translate('yes'),
                                                                    style: TextStyle(color: Colors.white),
                                                                  ),
                                                                  onPressed: isButtonDisabled
                                                                      ? null
                                                                      : () async {
                                                                    if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                        double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                      finalAmount = splitAmountController.text;
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        willPop = false;
                                                                        Navigator.of(context).pop();
                                                                      });
                                                                    } else {
                                                                      Fluttertoast.showToast(
                                                                          backgroundColor: Color(0xFFFF0000),
                                                                          msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                      splitAmountController.clear();
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    );
                                                  },
                                                ).then((_) {
                                                  if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                    setState(() {
                                                      split_payment = false;
                                                    });
                                                  }
                                                }) : null;
                                                setState(() {
                                                  isButtonDisabled = false;
                                                });
                                              },
                                              icon: Icon(Icons.payments_outlined, size: 20),
                                              label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                  : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                  style: TextStyle(fontSize: 14)
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible: split_payment,
                                            child: isload ? Container(
                                              padding: EdgeInsets.only(top: 20),
                                              height: 100,
                                              child: Center(
                                                child: ListView(
                                                    shrinkWrap: true,
                                                    // crossAxisCount: 5,
                                                    scrollDirection: Axis.horizontal,
                                                    children: List.generate(PaymentLists.length, (index) {
                                                      return GestureDetector(
                                                        onTap: () async {
                                                          setState(() {
                                                            _type = PaymentLists[index].type!;
                                                            order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                          });
                                                        },
                                                        child: Card(
                                                          elevation: 5,
                                                          color: Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(16.0),
                                                          ),
                                                          child: Container(
                                                            height: MediaQuery.of(context).size.height / 4,
                                                            width: 100,
                                                            child: Stack(
                                                              alignment: Alignment.center,
                                                              children: [
                                                                Text(
                                                                  '${PaymentLists[index].name}',
                                                                  textAlign: TextAlign.center,
                                                                  overflow: TextOverflow.clip,
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.w700,
                                                                    fontStyle: FontStyle.normal,
                                                                    fontSize: 15,
                                                                    color: Colors.blueGrey,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    })
                                                ),
                                              ),
                                            )
                                                : CustomProgressBar(),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                  : _type == 2
                              /// qr scan
                                  ? SingleChildScrollView(
                                    child: Container(
                                      height: split_payment ? 350 : 250,
                                      child: Column(
                                        children: [
                                      Container(
                                          alignment: Alignment.center,
                                          margin: EdgeInsets.only(bottom: 10),
                                          child: Text('Total: ${finalAmount}',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold))),
                                      Expanded(
                                        child: Container(
                                          height: scanning == false ? 150 : 200,
                                          margin: EdgeInsets.only(bottom: 10),
                                          child: scanning == false ?
                                          ClipRRect(
                                            child: Image(
                                              image: AssetImage("drawable/TNG.jpg"),
                                            ),
                                          ) :
                                          Container(
                                            width: 170,
                                            child: _buildQrViewMobile(context),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              style: ButtonStyle(
                                                backgroundColor: MaterialStateProperty.all(color.buttonColor),),
                                              onPressed: () async {
                                                setState(() {
                                                  scanning = !scanning;
                                                });
                                                //await controller?.resumeCamera();
                                                await controller?.scannedDataStream;
                                                // await callCreateOrder(finalAmount);
                                                if (this.isLogOut == true) {
                                                  openLogOutDialog();
                                                  return;
                                                }
                                              },
                                              icon: Icon(Icons.qr_code_scanner, size: 20),
                                              label: Text(scanning ? AppLocalizations.of(context)!.translate('cancel') : AppLocalizations.of(context)!.translate('scan_qr'),
                                                  style: TextStyle(fontSize: 16)),
                                            ),
                                            SizedBox(width: 10),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                              onPressed: () async {
                                                split_payment = !split_payment;
                                                paymentSplitDialog = true;
                                                splitAmountController.clear();
                                                if(!split_payment) {
                                                  paymentSplitDialog = false;
                                                }

                                                splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                      content: SizedBox(
                                                        height: 75.0,
                                                        width: 350.0,
                                                        child: ValueListenableBuilder(
                                                          valueListenable: splitAmountController,
                                                          builder: (context, TextEditingValue value, __) {
                                                            return Padding(
                                                              padding: const EdgeInsets.all(8.0),
                                                              child: TextField(
                                                                autofocus: true,
                                                                onSubmitted: (input) {
                                                                  if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                      double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                    finalAmount = splitAmountController.text;
                                                                    setState(() {
                                                                      isButtonDisabled = true;
                                                                      willPop = false;
                                                                      Navigator.of(context).pop();
                                                                    });
                                                                  } else {
                                                                    Fluttertoast.showToast(
                                                                        backgroundColor: Color(0xFFFF0000),
                                                                        msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                    splitAmountController.clear();
                                                                  }
                                                                },
                                                                controller: splitAmountController,
                                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                decoration: InputDecoration(
                                                                  border: OutlineInputBorder(
                                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                                  ),
                                                                  focusedBorder: OutlineInputBorder(
                                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                                  ),
                                                                  labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
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
                                                                    setState(() {
                                                                      isButtonDisabled = true;
                                                                      splitAmountController.clear();
                                                                      split_payment = !split_payment;
                                                                    });
                                                                    Navigator.of(context).pop();
                                                                    if (mounted) {
                                                                      setState(() {
                                                                        isButtonDisabled = false;
                                                                      });
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                width: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.width / 6 : MediaQuery.of(context).size.width / 4,
                                                                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 10,
                                                                child: ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: color.buttonColor,
                                                                  ),
                                                                  child: Text(
                                                                    AppLocalizations.of(context)!.translate('yes'),
                                                                    style: TextStyle(color: Colors.white),
                                                                  ),
                                                                  onPressed: isButtonDisabled
                                                                      ? null
                                                                      : () async {
                                                                    if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                        double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                      finalAmount = splitAmountController.text;
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        willPop = false;
                                                                        Navigator.of(context).pop();
                                                                      });
                                                                    } else {
                                                                      Fluttertoast.showToast(
                                                                          backgroundColor: Color(0xFFFF0000),
                                                                          msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                      splitAmountController.clear();
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    );
                                                  },
                                                ).then((_) {
                                                  if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                    setState(() {
                                                      split_payment = false;
                                                    });
                                                  }
                                                }) : null;
                                                setState(() {
                                                  isButtonDisabled = false;
                                                });
                                              },
                                              icon: Icon(Icons.payments_outlined, size: 20),
                                              label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                  : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                  style: TextStyle(fontSize: 16)),
                                            )
                                          ],
                                        ),
                                      ),
                                      Visibility(
                                        visible: split_payment,
                                        child: isload ? Container(
                                          padding: EdgeInsets.only(top: 20),
                                          height: 100,
                                          child: Center(
                                            child: ListView(
                                                shrinkWrap: true,
                                                // crossAxisCount: 5,
                                                scrollDirection: Axis.horizontal,
                                                children: List.generate(PaymentLists.length, (index) {
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      setState(() {
                                                        _type = PaymentLists[index].type!;
                                                        order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                      });
                                                    },
                                                    child: Card(
                                                      elevation: 5,
                                                      color: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16.0),
                                                      ),
                                                      child: Container(
                                                        height: MediaQuery.of(context).size.height / 4,
                                                        width: 100,
                                                        child: Stack(
                                                          alignment: Alignment.center,
                                                          children: [
                                                            Text(
                                                              '${PaymentLists[index].name}',
                                                              textAlign: TextAlign.center,
                                                              overflow: TextOverflow.clip,
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.w700,
                                                                fontStyle: FontStyle.normal,
                                                                fontSize: 15,
                                                                color: Colors.blueGrey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                })
                                            ),
                                          ),
                                        )
                                            : CustomProgressBar(),
                                      )
                                    ],
                                      ),
                                    ),
                                  )
                                  : Container(),
                            )
                          ],
                        ) :
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        _appSettingModel.table_order == 0
                                            ? AppLocalizations.of(context)!.translate('order_no') + ': ${getOrderNumber(cart, appSettingModel)}'
                                            : AppLocalizations.of(context)!.translate('table_no') + ': ${getSelectedTable()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: Card(
                                        elevation: 5,
                                        child: Column(
                                          children: [
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics: NeverScrollableScrollPhysics(),
                                              itemCount: itemList.length,
                                              padding: EdgeInsets.only(top: 10),
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  onTap: null,
                                                  isThreeLine: true,
                                                  title: RichText(
                                                    text: TextSpan(
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: '${itemList[index].product_name!} (${itemList[index].price!}/${itemList[index].per_quantity_unit!}${itemList[index].unit! == 'each' || itemList[index].unit! == 'each_c' ? 'each' : itemList[index].unit!})\n',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            color: color.backgroundColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text: "${currency_symbol}" + itemList[index].price!,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            color: color.backgroundColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    getVariant(itemList[index]) +
                                                        getModifier(itemList[index]) +
                                                        getRemark(itemList[index]),
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  trailing: Container(
                                                    child: FittedBox(
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            'x${itemList[index].quantity.toString()}',
                                                            style: TextStyle(
                                                              color: color.backgroundColor,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            SizedBox(height: 5),
                                            Divider(
                                              color: Colors.grey,
                                              height: 1,
                                              thickness: 1,
                                              indent: 20,
                                              endIndent: 20,
                                            ),
                                            SizedBox(height: 5),
                                            Container(
                                              constraints: BoxConstraints(
                                                maxHeight: MediaQuery.of(context).size.height / 2,
                                              ),
                                              child: ListView(
                                                controller: _controller,
                                                padding: EdgeInsets.only(left: 5, right: 5),
                                                physics: ClampingScrollPhysics(),
                                                children: [
                                                  ListTile(
                                                    title: Text('Subtotal', style: TextStyle(fontSize: 14)),
                                                    trailing: Text('${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                  ),
                                                  Visibility(
                                                    visible: hasSelectedPromo ? true : false,
                                                    child: ListTile(
                                                      title: SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Row(
                                                          children: [
                                                            Text('${allPromo} (${selectedPromoRate})', style: TextStyle(fontSize: 14)),
                                                          ],
                                                        ),
                                                      ),
                                                      trailing: Text('-${selectedPromo.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                      visualDensity: VisualDensity(vertical: -4),
                                                      dense: true,
                                                    ),
                                                  ),
                                                  Visibility(
                                                    visible: hasPromo == true ? true : false,
                                                    child: ListView.builder(
                                                      physics: NeverScrollableScrollPhysics(),
                                                      padding: EdgeInsets.zero,
                                                      shrinkWrap: true,
                                                      itemCount: autoApplyPromotionList.length,
                                                      itemBuilder: (context, index) {
                                                        return ListTile(
                                                          title: Text('${autoApplyPromotionList[index].name} (${autoApplyPromotionList[index].promoRate})',
                                                              style: TextStyle(fontSize: 14)),
                                                          visualDensity: VisualDensity(vertical: -4),
                                                          dense: true,
                                                          trailing: Text('-${autoApplyPromotionList[index].promoAmount!.toStringAsFixed(2)}',
                                                              style: TextStyle(fontSize: 14)),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  ListView.builder(
                                                    shrinkWrap: true,
                                                    padding: EdgeInsets.zero,
                                                    physics: NeverScrollableScrollPhysics(),
                                                    itemCount: taxList.length,
                                                    itemBuilder: (context, index) {
                                                      return ListTile(
                                                        title: Text('${taxList[index].name}(${taxList[index].tax_rate}%)'),
                                                        trailing: Text('${taxList[index].tax_amount?.toStringAsFixed(2)}'),
                                                        visualDensity: VisualDensity(vertical: -4),
                                                        dense: true,
                                                      );
                                                    },
                                                  ),
                                                  ListTile(
                                                    title: Text('Total', style: TextStyle(fontSize: 14)),
                                                    trailing: Text('${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                  ),
                                                  ListTile(
                                                    title: Text('Rounding', style: TextStyle(fontSize: 14)),
                                                    trailing: Text('${rounding.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    dense: true,
                                                  ),
                                                  for (int index = 0; index < paymentSplitList.length; index++)
                                                    ListTile(
                                                      title: Text('${paymentSplitList[index].payment_name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                      visualDensity: VisualDensity(vertical: -4),
                                                      dense: true,
                                                      trailing: Text('${paymentSplitList[index].payment_received!}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ListTile(
                                                    visualDensity: VisualDensity(vertical: -4),
                                                    title: Text('Final Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                    trailing: Text("${finalAmount}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                    dense: true,
                                                  ),
                                                ],
                                                shrinkWrap: true,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Divider(
                                              color: Colors.grey,
                                              height: 1,
                                              thickness: 1,
                                              indent: 20,
                                              endIndent: 20,
                                            ),
                                            SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(top: 40, bottom: 20),
                                      child: _type == 0
                                      /// cash
                                          ? Container(
                                        height: split_payment ? 350 : 250,
                                        child: Column(
                                          children: [
                                            Text("Total: ${finalAmount}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                            SizedBox(height: 10),
                                            Container(
                                              margin: EdgeInsets.only(bottom: 10),
                                              alignment: Alignment.centerLeft,
                                              child: Text('Change: ${change}'),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                children: [
                                                  GestureDetector(
                                                    behavior: HitTestBehavior.opaque,
                                                    onTap: () {
                                                      FocusScopeNode currentFocus = FocusScope.of(context);

                                                      if (!currentFocus.hasPrimaryFocus &&
                                                          currentFocus.focusedChild != null) {
                                                        FocusScope.of(context).unfocus();
                                                      }
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(bottom: 10),
                                                      child: ValueListenableBuilder(
                                                        valueListenable: inputController,
                                                        builder: (context, TextEditingValue value, __) {
                                                          return Container(
                                                            child: TextField(
                                                              onSubmitted: (value) {
                                                                makePayment();
                                                              },
                                                              onChanged: (value) {
                                                                calcChange(value);
                                                              },
                                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                              textAlign: TextAlign.right,
                                                              maxLines: 1,
                                                              controller: inputController,
                                                              decoration: InputDecoration(
                                                                border: OutlineInputBorder(borderSide: BorderSide(color: color.backgroundColor)),
                                                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color.backgroundColor)),
                                                              ),
                                                              style: TextStyle(fontSize: 30),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: color.backgroundColor,
                                                          ),
                                                          onPressed: isButtonDisable || itemList.isEmpty
                                                              ? null
                                                              : () async => makePayment(),
                                                          icon: Icon(Icons.payments, size: 20),
                                                          label: Text(AppLocalizations.of(context)!.translate('make_payment')),
                                                        ),
                                                        SizedBox(width: 10),
                                                        ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(backgroundColor: color.buttonColor),
                                                          onPressed: () {
                                                            inputController.clear();
                                                            setState(() {
                                                              change = '0.00';
                                                            });
                                                          },
                                                          icon: Icon(Icons.backspace, size: 20),
                                                          label: Text(AppLocalizations.of(context)!.translate('clear')),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                    onPressed: () async {
                                                      split_payment = !split_payment;
                                                      paymentSplitDialog = true;
                                                      splitAmountController.clear();
                                                      if(!split_payment) {
                                                        paymentSplitDialog = false;
                                                      }

                                                      splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                            content: SizedBox(
                                                              height: 75.0,
                                                              width: 350.0,
                                                              child: ValueListenableBuilder(
                                                                valueListenable: splitAmountController,
                                                                builder: (context, TextEditingValue value, __) {
                                                                  return Padding(
                                                                    padding: const EdgeInsets.all(8.0),
                                                                    child: TextField(
                                                                      autofocus: true,
                                                                      onSubmitted: (input) {
                                                                        if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                            double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                          finalAmount = splitAmountController.text;
                                                                          setState(() {
                                                                            isButtonDisabled = true;
                                                                            willPop = false;
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        } else {
                                                                          Fluttertoast.showToast(
                                                                              backgroundColor: Color(0xFFFF0000),
                                                                              msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                          splitAmountController.clear();
                                                                        }
                                                                      },
                                                                      controller: splitAmountController,
                                                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                      decoration: InputDecoration(
                                                                        border: OutlineInputBorder(
                                                                          borderSide: BorderSide(color: color.backgroundColor),
                                                                        ),
                                                                        focusedBorder: OutlineInputBorder(
                                                                          borderSide: BorderSide(color: color.backgroundColor),
                                                                        ),
                                                                        labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            actions: <Widget>[
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 1,
                                                                    child: SizedBox(
                                                                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 20,
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
                                                                          setState(() {
                                                                            isButtonDisabled = true;
                                                                            splitAmountController.clear();
                                                                            split_payment = !split_payment;
                                                                          });
                                                                          Navigator.of(context).pop();
                                                                          if (mounted) {
                                                                            setState(() {
                                                                              isButtonDisabled = false;
                                                                            });
                                                                          }
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(width: 10),
                                                                  Expanded(
                                                                    flex: 1,
                                                                    child: SizedBox(
                                                                      height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 20,
                                                                      child: ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: color.buttonColor,
                                                                        ),
                                                                        child: Text(
                                                                          AppLocalizations.of(context)!.translate('yes'),
                                                                          style: TextStyle(color: Colors.white),
                                                                        ),
                                                                        onPressed: isButtonDisabled
                                                                            ? null
                                                                            : () async {
                                                                          if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                              double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                            finalAmount = splitAmountController.text;
                                                                            setState(() {
                                                                              isButtonDisabled = true;
                                                                              willPop = false;
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                          } else {
                                                                            Fluttertoast.showToast(
                                                                                backgroundColor: Color(0xFFFF0000),
                                                                                msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                            splitAmountController.clear();
                                                                          }
                                                                        },
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              )
                                                            ],
                                                          );
                                                        },
                                                      ).then((_) {
                                                        if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                          setState(() {
                                                            split_payment = false;
                                                          });
                                                        }
                                                      }) : null;
                                                      setState(() {
                                                        isButtonDisabled = false;
                                                      });
                                                    },
                                                    icon: Icon(Icons.payments_outlined, size: 20),
                                                    label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                        : AppLocalizations.of(context)!.translate('split_payment_cancel')),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Visibility(
                                              visible: split_payment,
                                              child: isload ? Container(
                                                padding: EdgeInsets.only(top: 20),
                                                height: 100,
                                                child: Center(
                                                  child: ListView(
                                                      shrinkWrap: true,
                                                      // crossAxisCount: 5,
                                                      scrollDirection: Axis.horizontal,
                                                      children: List.generate(PaymentLists.length, (index) {
                                                        return GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              _type = PaymentLists[index].type!;
                                                              order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                            });
                                                          },
                                                          child: Card(
                                                            elevation: 5,
                                                            color: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16.0),
                                                            ),
                                                            child: Container(
                                                              height: MediaQuery.of(context).size.height / 4,
                                                              width: 100,
                                                              child: Stack(
                                                                alignment: Alignment.center,
                                                                children: [
                                                                  Text(
                                                                    '${PaymentLists[index].name}',
                                                                    textAlign: TextAlign.center,
                                                                    overflow: TextOverflow.clip,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.w700,
                                                                      fontStyle: FontStyle.normal,
                                                                      fontSize: 15,
                                                                      color: Colors.blueGrey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                  ),
                                                ),
                                              )
                                                  : CustomProgressBar(),
                                            )
                                          ],
                                        ),
                                      )
                                          : _type == 1
                                      /// card, ewallet
                                          ? Container(
                                        height: split_payment ? 420 : 320,
                                        padding: EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          children: [
                                            Text('Total: ${finalAmount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            Container(
                                              height: 150,
                                              margin: EdgeInsets.only(bottom: 10, top: 10),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16.0),
                                                child: Image(image: AssetImage("drawable/duitNow.jpg")),
                                              ),
                                            ),
                                            Container(
                                              child: ElevatedButton.icon(
                                                style: ButtonStyle(
                                                  backgroundColor: MaterialStateProperty.all(Colors.green),
                                                  padding: MaterialStateProperty.all(EdgeInsets.all(10)),
                                                ),
                                                onPressed: isButtonDisable || itemList.isEmpty
                                                    ? null
                                                    : () async {
                                                  setState(() {
                                                    isButtonDisable = true;
                                                  });
                                                  asyncQ.addJob((_) async {
                                                    try{
                                                      await callCreateOrder(finalAmount);
                                                      // await callCreateOrder(finalAmount);
                                                      if (this.isLogOut == true) {
                                                        openLogOutDialog();
                                                        return;
                                                      }
                                                      await openPaymentSuccessDialog(widget.dining_id, split_payment, isCashMethod: false, diningName: widget.dining_name);
                                                      Branch? data = await PosDatabase.instance.readLocalBranch();
                                                      if(data != null && data.allow_livedata == 1){
                                                        if(!isSyncisSyncingingNotifier.value){
                                                          isSyncisSyncingingNotifier.value = true;
                                                          do{
                                                            await syncToCloud.syncAllToCloud(isManualSync: true);
                                                          }while(syncToCloud.emptyResponse == false);
                                                          if(syncToCloud.emptyResponse == true){
                                                            isSyncisSyncingingNotifier.value = false;
                                                          }
                                                        }
                                                      }
                                                    }catch(e){
                                                      print("error: $e");
                                                    }
                                                  });
                                                },
                                                icon: Icon(Icons.call_received, size: 20),
                                                label: Text(AppLocalizations.of(context)!.translate('payment_received'), style: TextStyle(fontSize: 16)),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Container(
                                              child: ElevatedButton.icon(
                                                style: ButtonStyle(
                                                    backgroundColor: WidgetStateProperty.all(Colors.blue),
                                                    padding: WidgetStateProperty.all(EdgeInsets.all(10))),
                                                onPressed: () async {
                                                  split_payment = !split_payment;
                                                  paymentSplitDialog = true;
                                                  splitAmountController.clear();
                                                  if(!split_payment) {
                                                    paymentSplitDialog = false;
                                                  }

                                                  splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                        content: SizedBox(
                                                          height: 75.0,
                                                          width: 350.0,
                                                          child: ValueListenableBuilder(
                                                            valueListenable: splitAmountController,
                                                            builder: (context, TextEditingValue value, __) {
                                                              return Padding(
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: TextField(
                                                                  autofocus: true,
                                                                  onSubmitted: (input) {
                                                                    if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                        double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                      finalAmount = splitAmountController.text;
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        willPop = false;
                                                                        Navigator.of(context).pop();
                                                                      });
                                                                    } else {
                                                                      Fluttertoast.showToast(
                                                                          backgroundColor: Color(0xFFFF0000),
                                                                          msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                      splitAmountController.clear();
                                                                    }
                                                                  },
                                                                  controller: splitAmountController,
                                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                  decoration: InputDecoration(
                                                                    border: OutlineInputBorder(
                                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                                    ),
                                                                    focusedBorder: OutlineInputBorder(
                                                                      borderSide: BorderSide(color: color.backgroundColor),
                                                                    ),
                                                                    labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 1,
                                                                child: SizedBox(
                                                                  height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 20,
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
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        splitAmountController.clear();
                                                                        split_payment = !split_payment;
                                                                      });
                                                                      Navigator.of(context).pop();
                                                                      if (mounted) {
                                                                        setState(() {
                                                                          isButtonDisabled = false;
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(width: 10),
                                                              Expanded(
                                                                flex: 1,
                                                                child: SizedBox(
                                                                  height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 20,
                                                                  child: ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: color.buttonColor,
                                                                    ),
                                                                    child: Text(
                                                                      AppLocalizations.of(context)!.translate('yes'),
                                                                      style: TextStyle(color: Colors.white),
                                                                    ),
                                                                    onPressed: isButtonDisabled
                                                                        ? null
                                                                        : () async {
                                                                      if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                          double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                        finalAmount = splitAmountController.text;
                                                                        setState(() {
                                                                          isButtonDisabled = true;
                                                                          willPop = false;
                                                                          Navigator.of(context).pop();
                                                                        });
                                                                      } else {
                                                                        Fluttertoast.showToast(
                                                                            backgroundColor: Color(0xFFFF0000),
                                                                            msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                        splitAmountController.clear();
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      );
                                                    },
                                                  ).then((_) {
                                                    if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                      setState(() {
                                                        split_payment = false;
                                                      });
                                                    }
                                                  }) : null;
                                                  setState(() {
                                                    isButtonDisabled = false;
                                                  });
                                                },
                                                icon: Icon(Icons.payments_outlined, size: 20),
                                                label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                    : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                    style: TextStyle(fontSize: 16)
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: split_payment,
                                              child: isload ? Container(
                                                padding: EdgeInsets.only(top: 20),
                                                height: 100,
                                                child: Center(
                                                  child: ListView(
                                                      shrinkWrap: true,
                                                      // crossAxisCount: 5,
                                                      scrollDirection: Axis.horizontal,
                                                      children: List.generate(PaymentLists.length, (index) {
                                                        return GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              _type = PaymentLists[index].type!;
                                                              order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                            });
                                                          },
                                                          child: Card(
                                                            elevation: 5,
                                                            color: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16.0),
                                                            ),
                                                            child: Container(
                                                              height: MediaQuery.of(context).size.height / 4,
                                                              width: 100,
                                                              child: Stack(
                                                                alignment: Alignment.center,
                                                                children: [
                                                                  Text(
                                                                    '${PaymentLists[index].name}',
                                                                    textAlign: TextAlign.center,
                                                                    overflow: TextOverflow.clip,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.w700,
                                                                      fontStyle: FontStyle.normal,
                                                                      fontSize: 15,
                                                                      color: Colors.blueGrey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                  ),
                                                ),
                                              )
                                                  : CustomProgressBar(),
                                            )
                                          ],
                                        ),
                                      )
                                          : _type == 2
                                      /// qr scan
                                          ? Container(
                                        height: split_payment ? 400 : 330,
                                        child: Column(
                                          children: [
                                            Container(
                                              alignment: Alignment.center,
                                              margin: EdgeInsets.only(bottom: 10),
                                              child: Text('Total: ${finalAmount}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            ),
                                            Expanded(
                                              child: Container(
                                                // height: scanning == false ? 150 : 240,
                                                margin: EdgeInsets.only(bottom: 10),
                                                child: scanning == false
                                                    ? ClipRRect(
                                                  child: Image(image: AssetImage("drawable/TNG.jpg")),
                                                )
                                                    : Container(
                                                  width: 200,
                                                  child: _buildQrViewMobile(context),
                                                ),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              style: ButtonStyle(
                                                backgroundColor: MaterialStateProperty.all(color.buttonColor),
                                              ),
                                              onPressed: () async {
                                                setState(() {
                                                  scanning = !scanning;
                                                });
                                                await controller?.scannedDataStream;
                                                // await callCreateOrder(finalAmount);
                                                if (this.isLogOut == true) {
                                                  openLogOutDialog();
                                                  return;
                                                }
                                              },
                                              icon: Icon(Icons.qr_code_scanner, size: 20),
                                              label: Text(scanning ? AppLocalizations.of(context)!.translate('cancel') : AppLocalizations.of(context)!.translate('scan_qr'),
                                                  style: TextStyle(fontSize: 16)),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                              onPressed: () async {
                                                split_payment = !split_payment;
                                                paymentSplitDialog = true;
                                                splitAmountController.clear();
                                                if(!split_payment) {
                                                  paymentSplitDialog = false;
                                                }

                                                splitAmountController.text.isEmpty && paymentSplitDialog? await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(AppLocalizations.of(context)!.translate('split_payment_amount')),
                                                      content: SizedBox(
                                                        height: 75.0,
                                                        width: 350.0,
                                                        child: ValueListenableBuilder(
                                                          valueListenable: splitAmountController,
                                                          builder: (context, TextEditingValue value, __) {
                                                            return Padding(
                                                              padding: const EdgeInsets.all(8.0),
                                                              child: TextField(
                                                                autofocus: true,
                                                                onSubmitted: (input) {
                                                                  if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                      double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                    finalAmount = splitAmountController.text;
                                                                    setState(() {
                                                                      isButtonDisabled = true;
                                                                      willPop = false;
                                                                      Navigator.of(context).pop();
                                                                    });
                                                                  } else {
                                                                    Fluttertoast.showToast(
                                                                        backgroundColor: Color(0xFFFF0000),
                                                                        msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                    splitAmountController.clear();
                                                                  }
                                                                },
                                                                controller: splitAmountController,
                                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                                                decoration: InputDecoration(
                                                                  border: OutlineInputBorder(
                                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                                  ),
                                                                  focusedBorder: OutlineInputBorder(
                                                                    borderSide: BorderSide(color: color.backgroundColor),
                                                                  ),
                                                                  labelText: AppLocalizations.of(context)!.translate('amount'),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 20,
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
                                                                    setState(() {
                                                                      isButtonDisabled = true;
                                                                      splitAmountController.clear();
                                                                      split_payment = !split_payment;
                                                                    });
                                                                    Navigator.of(context).pop();
                                                                    if (mounted) {
                                                                      setState(() {
                                                                        isButtonDisabled = false;
                                                                      });
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Expanded(
                                                              flex: 1,
                                                              child: SizedBox(
                                                                height: MediaQuery.of(context).size.width > 900 && MediaQuery.of(context).size.height > 500 ? MediaQuery.of(context).size.height / 12 : MediaQuery.of(context).size.height / 20,
                                                                child: ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: color.buttonColor,
                                                                  ),
                                                                  child: Text(
                                                                    AppLocalizations.of(context)!.translate('yes'),
                                                                    style: TextStyle(color: Colors.white),
                                                                  ),
                                                                  onPressed: isButtonDisabled
                                                                      ? null
                                                                      : () async {
                                                                    if(splitAmountController.text != '' && double.parse(splitAmountController.text) != 0.0 &&
                                                                        double.parse(splitAmountController.text) < double.parse(finalAmount)){
                                                                      finalAmount = splitAmountController.text;
                                                                      setState(() {
                                                                        isButtonDisabled = true;
                                                                        willPop = false;
                                                                        Navigator.of(context).pop();
                                                                      });
                                                                    } else {
                                                                      Fluttertoast.showToast(
                                                                          backgroundColor: Color(0xFFFF0000),
                                                                          msg: AppLocalizations.of(context)!.translate('invalid_input'));
                                                                      splitAmountController.clear();
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    );
                                                  },
                                                ).then((_) {
                                                  if(splitAmountController.text == '' || double.parse(splitAmountController.text) == 0.0){
                                                    setState(() {
                                                      split_payment = false;
                                                    });
                                                  }
                                                }) : null;
                                                setState(() {
                                                  isButtonDisabled = false;
                                                });
                                              },
                                              icon: Icon(Icons.payments_outlined, size: 20),
                                              label: Text(!split_payment ? AppLocalizations.of(context)!.translate('split_payment')
                                                  : AppLocalizations.of(context)!.translate('split_payment_cancel'),
                                                  style: TextStyle(fontSize: 16)),
                                            ),
                                            Visibility(
                                              visible: split_payment,
                                              child: isload ? Container(
                                                padding: EdgeInsets.only(top: 20),
                                                height: 100,
                                                child: Center(
                                                  child: ListView(
                                                      shrinkWrap: true,
                                                      // crossAxisCount: 5,
                                                      scrollDirection: Axis.horizontal,
                                                      children: List.generate(PaymentLists.length, (index) {
                                                        return GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              _type = PaymentLists[index].type!;
                                                              order_split_payment_link_company_id = PaymentLists[index].payment_link_company_id!.toString();
                                                            });
                                                          },
                                                          child: Card(
                                                            elevation: 5,
                                                            color: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16.0),
                                                            ),
                                                            child: Container(
                                                              height: MediaQuery.of(context).size.height / 4,
                                                              width: 100,
                                                              child: Stack(
                                                                alignment: Alignment.center,
                                                                children: [
                                                                  Text(
                                                                    '${PaymentLists[index].name}',
                                                                    textAlign: TextAlign.center,
                                                                    overflow: TextOverflow.clip,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.w700,
                                                                      fontStyle: FontStyle.normal,
                                                                      fontSize: 15,
                                                                      color: Colors.blueGrey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                  ),
                                                ),
                                              )
                                                  : CustomProgressBar(),
                                            )
                                          ],
                                        ),
                                      )
                                          : Container(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                    ),
                  ),
                ),
              );
            }
          });
        });
        });
      });
    });
  }

  int getTotalOrderCache(List<PosTable> selectedTableList) {
    int tableSet = selectedTableList.where((table) => table.table_use_key != null).map((table) => table.table_use_key!).toSet().length;
    print("table set: ${tableSet}");
    return tableSet;
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 350.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  Widget _buildQrViewMobile(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = 200.00;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.redAccent,
          borderRadius: 5,
          borderLength: 20,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.translate('no_permission'))),
      );
    }
  }

  void _onQRViewCreated(QRViewController p1) {
    try{
      setState(() {
        this.controller = p1;
      });
      p1.scannedDataStream.listen((scanData) async {
        setState(() {
          isButtonDisable = true;
          result = scanData;
          print('result:${result?.code}');
        });
        p1.pauseCamera();
        //check login value
        // await checkDeviceLogin();
        // if (this.isLogOut == true) {
        //   openLogOutDialog();
        //   return;
        // }
        assetsAudioPlayer.open(
          Audio("audio/scan_sound.mp3"),
        );
        Map<String, dynamic> apiRes = await paymentApi();
        if (apiRes['status'] == '1') {
          asyncQ.addJob((_) async {
            try{
              await callCreateOrder(finalAmount, ipayTransId: apiRes['data']);
              assetsAudioPlayer.open(
                Audio("audio/payment_success.mp3"),
              );
              //pass trans id from api res to payment success dialog
              await openPaymentSuccessDialog(widget.dining_id, split_payment, isCashMethod: false, diningName: widget.dining_name, ipayTransId: apiRes['data']);
              Branch? data = await PosDatabase.instance.readLocalBranch();
              if(data != null && data.allow_livedata == 1){
                if(!isSyncisSyncingingNotifier.value){
                  isSyncisSyncingingNotifier.value = true;
                  do{
                    await syncToCloud.syncAllToCloud(isManualSync: true);
                  }while(syncToCloud.emptyResponse == false);
                  if(syncToCloud.emptyResponse == true){
                    isSyncisSyncingingNotifier.value = false;
                  }
                }
              }
            }catch(e){
              print("error: $e");
            }
          });
        } else {
          assetsAudioPlayer.open(
            Audio("audio/error_sound.mp3"),
          );
          Fluttertoast.showToast(
              backgroundColor: Color(0xFFFF0000), msg: "${apiRes['data']}");
          FLog.error(
            className: "make_payment_dialog",
            text: "paymentApi return error",
            exception: "ipay API res: ${apiRes['data']}",
          );
          Navigator.pop(context);
        }
      });
    }catch(e){
      FLog.error(
        className: "make_payment_dialog",
        text: "_onQRViewCreated error",
        exception: "$e",
      );
    }
  }

// function to calculate the input operation
//    equalPressed() {
//     String finaluserinput = userInput;
//     finaluserinput = userInput.replaceAll('x', '*');
//
//     Parser p = Parser();
//     Expression exp = p.parse(finaluserinput);
//     ContextModel cm = ContextModel();
//     double eval = exp.evaluate(EvaluationType.REAL, cm);
//     answer = eval.toString();
//   }
  Future<Future<Object?>> openPaymentSuccessDialog(String dining_id, bool splitPayment, {required isCashMethod, required String diningName, String? ipayTransId}) async {
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: PaymentSuccessDialog(
                isCashMethod: isCashMethod,
                dining_id: dining_id,
                orderCacheIdList: orderCacheIdList,
                selectedTableList: selectedTableList,
                callback: (orderKeyValue) async {
                  await getCallback(orderKeyValue);
                },
                orderId: orderId!,
                orderKey: orderKey!,
                change: change,
                dining_name: diningName,
                ipayTransId: ipayTransId,
                split_payment: splitPayment,
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

  getCallback(String orderKeyValue) {
    widget.callBack!(orderKeyValue);
  }

/*
  -----------------------Cart-item--------------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
  get item total price
*/
  getItemTotalPrice({required cartProductItem productItem}){
    return (double.parse(productItem.price!) * productItem.quantity!).toStringAsFixed(2);
  }

/*
  get order number
*/
  getOrderNumber(CartModel cart, AppSettingModel appSettingModel) {
    String? orderQueue = '';
    List<String> result = [];
    if(cart.cartNotifierItem.isNotEmpty) {
      for(int i = 0; i < cart.cartNotifierItem.length; i++) {
        if(cart.cartNotifierItem[i].order_queue != '' && cart.cartNotifierItem[i].order_queue != null)
          orderQueue = cart.cartNotifierItem[i].order_queue;
      }
      if(orderQueue != '')
        return orderQueue;
      else
        return '-';
    } else {
      return '-';
    }
  }

/*
  get selected table
*/
  getSelectedTable() {
    List<String> result = [];
    if (widget.dining_name == 'Dine in') {
      if (selectedTableList.isEmpty) {
        result.add('-');
      } else {
        for (int i = 0; i < selectedTableList.length; i++) {
          result.add('${selectedTableList[i].number}');
        }
      }
      return result.toString().replaceAll('[', '').replaceAll(']', '');
    } else {
      return '-';
    }
  }

/*
  get selected custom table
*/
  getSelectedCustomTable(CartModel cart, AppSettingModel appSettingModel) {
    String? customTable = '';
    List<String> result = [];
    if (widget.dining_name == 'Dine in' && appSettingModel.table_order == 2) {
      if(cart.cartNotifierItem.isNotEmpty) {
        for(int i = 0; i < cart.cartNotifierItem.length; i++) {
          if(cart.cartNotifierItem[i].custom_table_number != '' && cart.cartNotifierItem[i].custom_table_number != null) {
            customTable = cart.cartNotifierItem[i].custom_table_number;
          }
        }
        if(customTable == ''){
          if(cart.selectedTableIndex != '') {
            customTable = cart.selectedTableIndex;
          }
        }
        if(customTable != '')
          return customTable;
        else
          return '-';
      }
      return result.toString().replaceAll('[', '').replaceAll(']', '');
    } else {
      return '-';
    }
  }

/*
  Get Cart product modifier
*/
  getModifier(cartProductItem object) {
    List<String?> modifier = [];
    String result = '';
    if(object.modifier != null){
      var length = object.modifier!.length;
      for (int i = 0; i < length; i++) {
        ModifierGroup group = object.modifier![i];
        for (int j = 0; j < group.modifierChild!.length; j++) {
          if (group.modifierChild![j].isChecked!) {
            modifier.add(group.modifierChild![j].name! + '\n');
            result = modifier
                .toString()
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(',', '+')
                .replaceFirst('', '+ ');
          }
        }
      }
    } else {
      if(object.orderModifierDetail != null && object.orderModifierDetail!.isNotEmpty){
        for(int i = 0; i < object.orderModifierDetail!.length; i++){
          modifier.add(object.orderModifierDetail![i].mod_name! + '\n');
          result = modifier
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll(',', '+')
              .replaceFirst('', '+ ');
        }
      }
    }
    return result;
  }

/*
  Get Cart product variant
*/
  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    if(object.variant != null){
      var length = object.variant!.length;
      for (int i = 0; i < length; i++) {
        VariantGroup group = object.variant![i];
        for (int j = 0; j < group.child!.length; j++) {
          if (group.child![j].isSelected!) {
            variant.add(group.child![j].name!);
            result = "(${variant.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', ' |')})\n";
            //     variant.toString().replaceAll('[', '').replaceAll(']', '')
            // .replaceAll(',', '+')
            // .replaceAll('|', '\n+').replaceFirst('', '+ ');
          }
        }
      }
    } else {
      if(object.productVariantName != null && object.productVariantName != ''){
        result = "(${object.productVariantName!})\n";
      }
    }
    return result;
  }

/*
  Get Remark
*/
  getRemark(cartProductItem object) {
    String result = '';
    if (object.remark != '') {
      result = '*' + object.remark.toString();
    }
    return result;
  }

/*
  -------------------calculation-----------------------------------------------------------------------------------------------------------------------------------------------------
*/


  addAllPromotion(CartModel cartModel) {
    List<Promotion> promotionsToApply = [];

    // auto apply, specific_category != 0
    promotionsToApply.addAll(autoApplyPromotionList
        .where((promo) => promo.auto_apply == '1'));

    // manual apply, specific_category != 0
    if (cartModel.selectedPromotion != null &&
        cartModel.selectedPromotion!.auto_apply == '0' &&
        cartModel.selectedPromotion!.specific_category != '0') {
      promotionsToApply.add(cartModel.selectedPromotion!);
    }

    // auto apply, specific_category == 0
    promotionsToApply.addAll(autoApplyPromotionList
        .where((promo) => promo.auto_apply == '1' && promo.specific_category == '0'));

    // manual apply, specific_category == 0
    if (cartModel.selectedPromotion != null &&
        cartModel.selectedPromotion!.auto_apply == '0' &&
        cartModel.selectedPromotion!.specific_category == '0') {
      promotionsToApply.add(cartModel.selectedPromotion!);
    }

    for (var promo in promotionsToApply) {
      if (!appliedPromotionList.contains(promo)) {
        appliedPromotionList.add(promo);
      }
    }
  }

  getCartItemList(CartModel cart) {
    print("getCartItemList called");
    try {
      if(orderCacheIdList.isEmpty){
        for (int i = 0; i < cart.cartNotifierItem.length; i++) {
          if (!orderCacheIdList.contains(cart.cartNotifierItem[i].order_cache_sqlite_id!)) {
            orderCacheIdList.add(cart.cartNotifierItem[i].order_cache_sqlite_id!);
            orderCacheSqliteId = cart.cartNotifierItem[i].order_cache_sqlite_id!;
          }
        }
      }
      if(cart.selectedTable.isNotEmpty && selectedTableList.isEmpty){
        for (int j = 0; j < cart.selectedTable.length; j++) {
          if (!selectedTableList.contains(cart.selectedTable[j].table_sqlite_id)) {
            selectedTableList.add(cart.selectedTable[j]);
          }
        }
      }
      if(cart.cartNotifierItem.isNotEmpty && itemList.isEmpty){
        itemList.addAll((cart.cartNotifierItem));
      }
      for(int k = 0; k < itemList.length; k++) {
        itemList[k].promo = {};
        itemList[k].charge = {};
        itemList[k].tax = {};
      }
      calculateCategoryPriceBeforePromo(cart);

      // get order promo detail
      calculatePromotion(appliedPromotionList);

      // get order charge detail
      calculateCharges(taxList);

      // get order tax detail
      calculateTaxes(taxList);

      for(int i = 0; i<itemList.length; i++)
        print("itemListPromo: ${jsonEncode(itemList[i].product_name)}, ${jsonEncode(itemList[i].promo)}");
      for(int i = 0; i<itemList.length; i++)
        print("itemListCharge: ${jsonEncode(itemList[i].product_name)}, ${jsonEncode(itemList[i].charge!)}");
      for(int i = 0; i<itemList.length; i++)
        print("itemListTax: ${jsonEncode(itemList[i].product_name)}, ${jsonEncode(itemList[i].tax ?? '0')}");
    } catch(e){
      FLog.error(
        className: "make_payment_dialog",
        text: "getCartItemList error",
        exception: "$e",
      );
    }
  }

  calculatePromotion(List appliedPromotionList) {
    try {
      if (appliedPromotionList.isEmpty) return;

      double _calculateSingleItemDiscount(dynamic data) {
        return data.promo!.entries.where((item) => !item.value.isNaN).fold(0.0, (sum, item) => sum + item.value);
      }

      double _calculateCategoryTotal({String? categoryId, bool Function(dynamic)? filter,}) {
        return itemList.fold(0.0, (total, data) {
          if (filter != null && !filter(data)) return total;

          double singleItemDiscount = _calculateSingleItemDiscount(data);

          return total + (double.parse(data.price!) * data.quantity!) - singleItemDiscount;
        });
      }

      _adjustPromoAmount(dynamic promotion) {
        double appliedPromoAmount = itemList.fold(0.0, (total, data) {
          return total + data.promo!.entries.where((item) => item.key == promotion.name && !item.value.isNaN).fold(0.0, (sum, item) => sum + item.value);
        });

        double compareAmount = double.parse(
            (appliedPromoAmount - promotion.promoAmount!).toStringAsFixed(2)
        );

        if (compareAmount == 0) return;

        int loopCount = (compareAmount * 100).round().abs();
        int x = 0;
        bool isRoundingUp = compareAmount < 0;

        while (x < loopCount) {
          for (var data in itemList) {
            if (x >= loopCount) break;

            for (var item in data.promo!.entries) {
              if (item.key == promotion.name) {
                data.promo![item.key] = data.promo![item.key]! + (isRoundingUp ? 0.01 : -0.01);
                data.promo![item.key] = double.parse(data.promo![item.key]!.toStringAsFixed(2));
                x++;
              }
            }
          }
        }
      }

      _applyPromoToItems(dynamic promotion, double total, bool Function(dynamic) filter) {
        for (var data in itemList) {
          if (!filter(data)) continue;

          double singleItemDiscount = _calculateSingleItemDiscount(data);

          double promoAmountApplied = promotion.promoAmount! * (double.parse(data.price!) * data.quantity! - singleItemDiscount) /total;

          data.promo![promotion.name!] = double.parse(promoAmountApplied.toStringAsFixed(2));
        }

        _adjustPromoAmount(promotion);
      }

      for (var promotion in appliedPromotionList) {
        if ((promotion.auto_apply == '1' && promotion.specific_category != '0') ||
            (promotion.auto_apply == '0' && promotion.specific_category != '0')) {

          if (promotion.specific_category == '1') {
            double categoryTotal = _calculateCategoryTotal(filter: (data) => data.category_id == promotion.category_id);

            _applyPromoToItems(promotion, categoryTotal, (data) => data.category_id == promotion.category_id);
          } else {
            double categoryTotal = _calculateCategoryTotal(filter: (data) => promotion.multiple_category!.any((category) => category['category_id'].toString() == data.category_id));

            _applyPromoToItems(promotion, categoryTotal, (data) => promotion.multiple_category!.any((category) => category['category_id'].toString() == data.category_id));
          }
        } else if ((promotion.auto_apply == '1' && promotion.specific_category == '0') ||
            (promotion.auto_apply == '0' && promotion.specific_category == '0')) {
          double total = _calculateCategoryTotal();

          _applyPromoToItems(promotion, total, (_) => true);
        }
      }

      double totalPromotions = itemList.fold(0.0, (total, item) {
        return total + item.promo!.values.fold(0.0, (sum, promoValue) => sum + promoValue);
      });
      print("Total promotions: ${totalPromotions.toStringAsFixed(2)}");
    } catch(e) {
      FLog.error(
        className: "make_payment_dialog",
        text: "calculatePromotion error",
        exception: "$e",
      );
    }
  }

  calculateCharges(List<dynamic> taxList) {
    try {
      adjustChargeRoundingDifference(List<dynamic> items, String chargeName, double compareAmount) {
        int loopCount = (compareAmount * 100).round().abs();
        int x = 0;
        bool isRoundingUp = compareAmount < 0;

        while (x < loopCount) {
          for (var item in items) {
            if (x >= loopCount) break;

            if (item.charge!.containsKey(chargeName)) {
              item.charge![chargeName] += isRoundingUp ? 0.01 : -0.01;
              item.charge![chargeName] = double.parse(item.charge![chargeName].toStringAsFixed(2));
              x++;
            }
          }
        }
      }

      double calculateDiscountedPrice(dynamic item) {
        double singleItemDiscount = item.promo!.entries.where((entry) => !entry.value.isNaN).map((entry) => entry.value).fold(0.0, (a, b) => a + b);
        return (double.parse(item.price!) * item.quantity!) - singleItemDiscount;
      }

      distributeChargesAcrossItems(dynamic chargeItem, bool isSpecificCategory) {
        double totalAmount = 0;
        List<dynamic> eligibleItems = isSpecificCategory
            ? itemList.where((item) => chargeItem.multiple_category!.any((category) => category['category_id'].toString() == item.category_id)).toList()
            : itemList;

        double subtotalAfterPromoTotal = eligibleItems.map(calculateDiscountedPrice).fold(0.0, (a, b) => a + b);

        for (var item in eligibleItems) {
          double singleItemDiscountedPrice = calculateDiscountedPrice(item);
          double distributedCharge = chargeItem.tax_amount! * singleItemDiscountedPrice / subtotalAfterPromoTotal;

          item.charge ??= {};
          item.charge![chargeItem.name!] = double.parse(distributedCharge.toStringAsFixed(2));
        }

        double totalDistributedCharge = eligibleItems.expand((item) => item.charge!.entries).where((entry) => entry.key == chargeItem.name).map((entry) => entry.value).fold(0.0, (a, b) => a + b);

        double compareAmount = double.parse((totalDistributedCharge - chargeItem.tax_amount!).toStringAsFixed(2));

        if (compareAmount != 0) {
          adjustChargeRoundingDifference(eligibleItems, chargeItem.name!, compareAmount);
        }
      }

      for (var chargeItem in taxList.where((item) => item.type == 0)) {
        bool isSpecificCategory = chargeItem.specific_category == 1;
        distributeChargesAcrossItems(chargeItem, isSpecificCategory);
      }

      double totalCharges = itemList.expand((item) => item.charge!.values).fold(0.0, (a, b) => a + b);
      print("Total charges: ${totalCharges.toStringAsFixed(2)}");
    } catch(e) {
      FLog.error(
        className: "make_payment_dialog",
        text: "calculateCharges error",
        exception: "$e",
      );
    }
  }

  calculateTaxes(List<dynamic> taxList) {
    try {
      adjustTaxRoundingDifference(List<dynamic> items, String taxName, double compareAmount) {
        int loopCount = (compareAmount * 100).round().abs();
        int x = 0;
        bool isRoundingUp = compareAmount < 0;

        while (x < loopCount) {
          for (var item in items) {
            if (x >= loopCount) break;

            if (item.tax!.containsKey(taxName)) {
              item.tax![taxName] += isRoundingUp ? 0.01 : -0.01;
              item.tax![taxName] = double.parse(item.tax![taxName].toStringAsFixed(2));
              x++;
            }
          }
        }
      }

      double calculateDiscountedPrice(dynamic item) {
        double singleItemDiscount = item.promo!.entries.where((entry) => !entry.value.isNaN).map((entry) => entry.value).fold(0.0, (a, b) => a + b);
        return (double.parse(item.price!) * item.quantity!) - singleItemDiscount;
      }

      distributeTaxesAcrossItems(dynamic taxItem, bool isSpecificCategory) {
        List<dynamic> eligibleItems = isSpecificCategory
            ? itemList.where((item) => taxItem.multiple_category!.any((category) => category['category_id'].toString() == item.category_id)).toList()
            : itemList;

        double subtotalAfterPromoTotal = eligibleItems.map(calculateDiscountedPrice).fold(0.0, (a, b) => a + b);

        for (var item in eligibleItems) {
          double singleItemDiscountedPrice = calculateDiscountedPrice(item);
          double distributedTax = taxItem.tax_amount! * singleItemDiscountedPrice / subtotalAfterPromoTotal;

          item.tax ??= {};
          item.tax![taxItem.name!] = double.parse(distributedTax.toStringAsFixed(2));
        }

        double totalDistributedTax = eligibleItems.expand((item) => item.tax!.entries).where((entry) => entry.key == taxItem.name).map((entry) => entry.value).fold(0.0, (a, b) => a + b);
        double compareAmount = double.parse((totalDistributedTax - taxItem.tax_amount!).toStringAsFixed(2));

        if (compareAmount != 0) {
          adjustTaxRoundingDifference(eligibleItems, taxItem.name!, compareAmount);
        }
      }

      for (var taxItem in taxList.where((item) => item.type == 1)) {
        bool isSpecificCategory = taxItem.specific_category == 1;
        distributeTaxesAcrossItems(taxItem, isSpecificCategory);
      }

      double totalTaxes = itemList.expand((item) => item.tax!.values).fold(0.0, (a, b) => a + b);
      print("Total taxes: ${totalTaxes.toStringAsFixed(2)}");
    } catch(e) {
      FLog.error(
        className: "make_payment_dialog",
        text: "calculateTaxes error",
        exception: "$e",
      );
    }
  }

  calculateCategoryPriceBeforePromo(CartModel cart){
    try {
      cart.clearCategoryTotalPriceMapBeforePromo();
      for (int i = 0; i < cart.cartNotifierItem.length; i++) {
        double thisProductTotalPrice = double.parse(cart.cartNotifierItem[i].price!) * cart.cartNotifierItem[i].quantity!;
        if (!cart.categoryTotalPriceMapBeforePromo.containsKey(cart.cartNotifierItem[i].category_id)) {
          // category not exist in map
          cart.addCategoryTotalPriceBeforePromo(cart.cartNotifierItem[i].category_id!, thisProductTotalPrice);
        } else {
          // category exist in map
          double currentCategoryPrice = cart.categoryTotalPriceMapBeforePromo[cart.cartNotifierItem[i].category_id]!;
          cart.categoryTotalPriceMapBeforePromo[cart.cartNotifierItem[i].category_id!] = currentCategoryPrice + thisProductTotalPrice;
        }
      }
    } catch(e){
      FLog.error(
        className: "make_payment_dialog",
        text: "calculateCategoryPriceBeforePromo error",
        exception: e,
      );
    }
  }

  getReceiptPaymentDetail(CartModel cart) {
    for (int i = 0; i < cart.cartNotifierPayment.length; i++) {
      this.total = cart.cartNotifierPayment[i].subtotal;
      this.totalAmount = cart.cartNotifierPayment[i].amount;
      this.rounding = cart.cartNotifierPayment[i].rounding;
      this.finalAmount = splitAmountController.text.isNotEmpty ? (double.parse(splitAmountController.text)).toStringAsFixed(2) : cart.cartNotifierPayment[i].finalAmount;
      this.diningName = widget.dining_name;
      statisFinalAmount = cart.cartNotifierPayment[i].finalAmount;
      if(taxList.isEmpty && cart.cartNotifierPayment[i].taxList!.isNotEmpty){
        this.taxList.addAll(cart.cartNotifierPayment[i].taxList!);
      }
      if(cart.cartNotifierPayment[i].promotionList!.isNotEmpty && autoApplyPromotionList.isEmpty){
        this.autoApplyPromotionList.addAll(cart.cartNotifierPayment[i].promotionList!);
      }
    }
    if (cart.selectedPromotion != null) {
      hasSelectedPromo = true;
      this.allPromo = cart.selectedPromotion!.name;
      this.selectedPromoRate = cart.selectedPromotion!.promoRate!;
      this.selectedPromo = cart.selectedPromotion!.promoAmount!;
    }
    addAllPromotion(cart);
    if (myCount == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _scrollDown();
        });
      });
      myCount++;
    }
    //streamController.add('refresh');
    // if (!controller.isClosed) {
    //   controller.sink.add('refresh');
    // }
  }

  getTotalDiscount() {
    double _totalDiscount = 0.0;
    if (autoApplyPromotionList.isNotEmpty) {
      for (int i = 0; i < autoApplyPromotionList.length; i++) {
        _totalDiscount += autoApplyPromotionList[i].promoAmount!;
      }
    }
    if (hasSelectedPromo) {
      _totalDiscount += selectedPromo;
    }

    return _totalDiscount.toStringAsFixed(2);
  }

  getTotalTax() {
    double _totalTax = 0.0;
    if (taxList.isNotEmpty) {
      for (int i = 0; i < taxList.length; i++) {
        _totalTax += taxList[i].tax_amount!;
      }
    }
    return _totalTax.toStringAsFixed(2);
  }

/*
  -------------------DB Query---------------------------------------------------------------------------------------------------------------------------------------------------------
*/
  readAllBranchLinkDiningOption() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<BranchLinkDining> data = await PosDatabase.instance
        .readBranchLinkDiningOption(branch_id!.toString());
    for (int i = 0; i < data.length; i++) {
      branchLinkDiningIdList.add(data[i].dining_id!);
    }

    streamController.add('refresh');
  }

  callCreateOrder(String? paymentReceived, {orderChange, String? ipayTransId}) async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    OrderCache orderCacheData = await PosDatabase.instance.readSpecificOrderCacheByLocalId(int.parse(orderCacheSqliteId));
    if(orderCacheData.order_key == null || orderCacheData.order_key == '') {
      await createOrder(double.parse(paymentReceived!), orderChange, ipayTransId: ipayTransId);
      await crateOrderTaxDetail();
      await createOrderPromotionDetail();
      await updateOrderDetail(dateTime);
      //await syncAllToCloud();
    }

    List<Order> orderData = [];
    // first split
    if(orderKey != null){
      orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(orderKey!);
      this.orderId = orderData[0].order_sqlite_id.toString();
    } else if(orderCacheData.order_key != null) {
      // second split
      orderData = await PosDatabase.instance.readSpecificOrderByOrderKey(orderCacheData.order_key!);
      this.orderId = orderData[0].order_sqlite_id.toString();
      this.orderKey = orderCacheData.order_key;
    }

    if(orderData.isNotEmpty) {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
      String dateTime = dateFormat.format(DateTime.now());
      if(orderData.first.payment_split == 2){
        await createOrderPaymentSplit(double.parse(paymentReceived!), orderChange, orderData[0].order_key!, ipayTransId: ipayTransId);
        List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(orderKey!);
        double newOrderAmount = 0.0;
        for(int k = 0; k < orderSplit.length; k++){
          newOrderAmount += double.parse(orderSplit[k].amount!);
        }
        // update order payment received and change
        try {
          double initPaymentReceived = orderData[0].payment_received != '' && orderData[0].payment_received != null ? double.parse(orderData[0].payment_received!) : 0.0;
          double initPaymentChange = orderData[0].payment_change != '' && orderData[0].payment_change != null ? double.parse(orderData[0].payment_change!) : 0.0;
          double newPaymentReceived = paymentReceived != '' && paymentReceived != null ? double.parse(paymentReceived) : 0.0;
          double newPaymentChange = orderChange != '' && orderChange != null ? double.parse(orderChange) : 0.0;

          print("split_payment_status: ${split_payment ? orderData[0].payment_split : 1}");

          await PosDatabase.instance.updateOrderPaymentSplit(Order(
            payment_received: (initPaymentReceived + newPaymentReceived).toStringAsFixed(2),
            payment_change: (initPaymentChange + newPaymentChange).toStringAsFixed(2),
            payment_split: split_payment ? orderData[0].payment_split : 1,
            sync_status: orderData[0].sync_status == 0 ? 0 : 2,
            updated_at: dateTime,
            soft_delete: '',
            order_sqlite_id: orderData[0].order_sqlite_id
          ));
        } catch(e) {
          print("updateOrderPaymentSplit error: $e");
          FLog.error(
            className: "make_payment_dialog",
            text: "Update new payment split payment received and change in Order",
            exception: e,
          );
        }

      } else {
      }
    }
  }

  readBranchPref() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

  generateOrderKey(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes = order.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
        order.order_sqlite_id.toString() +
        device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  generateOrderNumber() {
    int orderNum = 0;
    if (orderList.isNotEmpty) {
      orderNum = int.parse(orderList[0].order_number!) + 1;
    } else {
      orderNum = 1;
    }
    return orderNum;
  }

  Future<int> readQueueFromOrderCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<OrderCache> orderCacheList = await PosDatabase.instance.readSpecificOrderCache(orderCacheSqliteId);
      int orderQueue = 0;
      orderQueue = orderCacheList[0].order_queue! != '' ? int.parse(orderCacheList[0].order_queue!) : -1;
      return orderQueue;
    } catch(e) {
      print("readQueueFromOrderCache error: ${e}");
    }
    return -1;
  }

  createOrder(double? paymentReceived, String? orderChange, {String? ipayTransId}) async {
    print('create order called');
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final String? pos_user = prefs.getString('pos_pin_user');
    AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
    Map logInUser = json.decode(login_user!);
    Map userObject = json.decode(pos_user!);
    int orderNum = generateOrderNumber();
    int orderQueue = localSetting!.enable_numbering == 1 ? await readQueueFromOrderCache() : 0;
    try {
      if (orderNum != 0) {
        Order orderObject = Order(
            order_id: 0,
            order_number: orderNum.toString().padLeft(5, '0'),
            // order_queue: localSetting!.enable_numbering == 1 ? orderQueue.toString().padLeft(4, '0') : '',
            order_queue: localSetting.enable_numbering == 1 && orderQueue != -1 ? orderQueue.toString().padLeft(4, '0') : '',
            company_id: logInUser['company_id'].toString(),
            branch_id: branch_id.toString(),
            customer_id: '',
            dining_id: widget.dining_id,
            dining_name: this.diningName,
            branch_link_promotion_id: '',
            payment_link_company_id: split_payment ? '0' : widget.payment_link_company_id.toString(),
            branch_link_tax_id: '',
            subtotal: total.toStringAsFixed(2),
            amount: totalAmount.toStringAsFixed(2),
            rounding: rounding.toStringAsFixed(2),
            final_amount: statisFinalAmount,
            close_by: userObject['name'].toString(),
            payment_received: split_payment || paymentReceived == null ? '' : paymentReceived.toStringAsFixed(2),
            payment_change: split_payment || orderChange == null ? '0.00' : orderChange,
            payment_status: 0,
            payment_split: split_payment ? 2 : 0,
            order_key: '',
            refund_sqlite_id: '',
            refund_key: '',
            settlement_sqlite_id: '',
            settlement_key: '',
            ipay_trans_id: split_payment ? '' : ipayTransId ?? '',
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        Order data = await PosDatabase.instance.insertSqliteOrder(orderObject);
        this.orderId = data.order_sqlite_id.toString();
        Order updatedOrder = await insertOrderKey();
        _value.add(jsonEncode(updatedOrder));
        order_value = _value.toString();
        //await syncOrderToCloud(updatedOrder);
      }
    } catch (e) {
      print('create order error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('create_order_error') +
              " ${e}");
      FLog.error(
        className: "make_payment_dialog",
        text: "Create order failed",
        exception: "$e\norderNum: $orderNum",
      );
    }
  }

  createOrderPaymentSplit(double? paymentReceived, String? orderChange, String tempOrderKey, {String? ipayTransId}) async {
    print('create order payment split called');
    List<String> _value = [];
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final String? login_user = prefs.getString('user');
    final int? branch_id = prefs.getInt('branch_id');
    final String? pos_user = prefs.getString('pos_pin_user');
    AppSetting? localSetting = await PosDatabase.instance.readLocalAppSetting(branch_id.toString());
    Map logInUser = json.decode(login_user!);
    Map userObject = json.decode(pos_user!);
    int orderNum = generateOrderNumber();
    int orderQueue = localSetting!.enable_numbering == 1 ? await readQueueFromOrderCache() : 0;
    try {
      if (orderNum != 0) {
        OrderPaymentSplit orderObject = OrderPaymentSplit(
            order_payment_split_id: 0,
            order_payment_split_key: '',
            branch_id: branch_id.toString(),
            payment_link_company_id: order_split_payment_link_company_id != '' ? order_split_payment_link_company_id : widget.payment_link_company_id.toString(),
            amount: finalAmount,
            payment_received: paymentReceived == null ? '' : paymentReceived.toStringAsFixed(2),
            payment_change: orderChange == null ? '0.00' : orderChange,
            order_key: tempOrderKey,
            ipay_trans_id: ipayTransId ?? '',
            sync_status: 0,
            created_at: dateTime,
            updated_at: '',
            soft_delete: '');
        OrderPaymentSplit data = await PosDatabase.instance.insertSqliteOrderPaymentSplit(orderObject);
        OrderPaymentSplit? returnData = await insertOrderPaymentSplitKey(data, dateTime);
        // this.orderId = data.order_payment_split_id.toString();
        // order_value = _value.toString();
        //await syncOrderToCloud(updatedOrder);
      }
    } catch (e) {
      print('create order payment split error: ${e}');
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('create_order_error') +
              " ${e}");
    }
  }

  insertOrderPaymentSplitKey(OrderPaymentSplit orderPaymentSplit, String dateTime) async {
    OrderPaymentSplit? returnData;
    String key = await generateOrderPaymentSplitKey(orderPaymentSplit);
    OrderPaymentSplit data = OrderPaymentSplit(
        updated_at: dateTime,
        sync_status: 0,
        order_payment_split_key: key,
        order_payment_split_sqlite_id: orderPaymentSplit.order_payment_split_sqlite_id
    );
    int status =  await PosDatabase.instance.updateOrderPaymentSplitUniqueKey(data);
    return returnData;
  }

  generateOrderPaymentSplitKey(OrderPaymentSplit orderPaymentSplit) async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    var bytes = orderPaymentSplit.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') + orderPaymentSplit.order_payment_split_id.toString() + branch_id.toString();
    // return md5.convert(utf8.encode(bytes)).toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    print("hashKey: ${Utils.shortHashString(hashCode: md5Hash)}");
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertOrderKey() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    List<String> _value = [];
    Order? _updatedOrder;
    await readAllOrder();
    orderKey = await generateOrderKey(orderList[0]);
    if (orderKey != null) {
      Order orderObject = Order(
          order_key: orderKey,
          sync_status: 0,
          updated_at: dateTime,
          order_sqlite_id: orderList[0].order_sqlite_id);
      int updatedData =
          await PosDatabase.instance.updateOrderUniqueKey(orderObject);
      if (updatedData == 1) {
        Order orderData = await PosDatabase.instance
            .readSpecificOrder(orderObject.order_sqlite_id!);
        _updatedOrder = orderData;
        //_value.add(jsonEncode(orderData));
      }
    }
    return _updatedOrder;
  }

  generateOrderPromotionDetailKey(
      OrderPromotionDetail orderPromotionDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        orderPromotionDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderPromotionDetail.order_promotion_detail_sqlite_id.toString() +
            device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertOrderPromotionDetailKey(
      OrderPromotionDetail orderPromotionDetail, String dateTime) async {
    String? _key;
    OrderPromotionDetail? _data;
    _key = await generateOrderPromotionDetailKey(orderPromotionDetail);
    if (_key != null) {
      OrderPromotionDetail orderPromoDetailObject = OrderPromotionDetail(
          order_promotion_detail_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          order_promotion_detail_sqlite_id:
              orderPromotionDetail.order_promotion_detail_sqlite_id);
      int updatedData = await PosDatabase.instance
          .updateOrderPromotionDetailUniqueKey(orderPromoDetailObject);
      if (updatedData == 1) {
        OrderPromotionDetail orderPromotionDetailData = await PosDatabase
            .instance
            .readSpecificOrderPromotionDetailByLocalId(
                orderPromoDetailObject.order_promotion_detail_sqlite_id!);
        _data = orderPromotionDetailData;
      }
    }
    return _data;
  }

  createOrderPromotionDetail() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<String> _value = [];

    for (int i = 0; i < appliedPromotionList.length; i++) {
      List<BranchLinkPromotion> branchPromotionData = await PosDatabase.instance
          .readSpecificBranchLinkPromotion(branch_id.toString(),
              appliedPromotionList[i].promotion_id.toString());
      OrderPromotionDetail data = await PosDatabase.instance
          .insertSqliteOrderPromotionDetail(OrderPromotionDetail(
              order_promotion_detail_id: 0,
              order_promotion_detail_key: '',
              order_sqlite_id: orderId,
              order_id: '0',
              order_key: orderKey,
              promotion_name: appliedPromotionList[i].name,
              promotion_id: appliedPromotionList[i].promotion_id.toString(),
              rate: appliedPromotionList[i].promoRate,
              promotion_amount:
                  appliedPromotionList[i].promoAmount!.toStringAsFixed(2),
              promotion_type: appliedPromotionList[i].type,
              branch_link_promotion_id:
                  branchPromotionData[0].branch_link_promotion_id.toString(),
              auto_apply: appliedPromotionList[i].auto_apply!,
              sync_status: 0,
              created_at: dateTime,
              updated_at: '',
              soft_delete: ''));
      OrderPromotionDetail returnData =
          await insertOrderPromotionDetailKey(data, dateTime);
      _value.add(jsonEncode(returnData));
    }
    order_promotion_value = _value.toString();
  }

  generateOrderTaxDetailKey(OrderTaxDetail orderTaxDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final int? device_id = prefs.getInt('device_id');
    var bytes =
        orderTaxDetail.created_at!.replaceAll(new RegExp(r'[^0-9]'), '') +
            orderTaxDetail.order_tax_detail_sqlite_id.toString() +
            device_id.toString();
    var md5Hash = md5.convert(utf8.encode(bytes));
    return Utils.shortHashString(hashCode: md5Hash);
  }

  insertOrderTaxDetailKey(
      OrderTaxDetail orderTaxDetail, String dateTime) async {
    String? _key;
    OrderTaxDetail? _data;
    _key = await generateOrderTaxDetailKey(orderTaxDetail);
    if (_key != null) {
      OrderTaxDetail orderTaxDetailObject = OrderTaxDetail(
          order_tax_detail_key: _key,
          sync_status: 0,
          updated_at: dateTime,
          order_tax_detail_sqlite_id:
              orderTaxDetail.order_tax_detail_sqlite_id);
      int updatedData = await PosDatabase.instance
          .updateOrderTaxDetailUniqueKey(orderTaxDetailObject);
      if (updatedData == 1) {
        OrderTaxDetail orderTaxDetailData = await PosDatabase.instance
            .readSpecificOrderTaxDetailByLocalId(
                orderTaxDetailObject.order_tax_detail_sqlite_id!);
        _data = orderTaxDetailData;
      }
    }
    return _data;
  }

  crateOrderTaxDetail() async {
    print('order tax detail called');
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    List<String> _value = [];

    for (int i = 0; i < taxList.length; i++) {
      List<BranchLinkTax> branchTaxData = await PosDatabase.instance
          .readSpecificBranchLinkTax(
              branch_id.toString(), taxList[i].tax_id.toString());
      if (branchTaxData.length > 0) {
        OrderTaxDetail data = await PosDatabase.instance
            .insertSqliteOrderTaxDetail(OrderTaxDetail(
                order_tax_detail_id: 0,
                order_tax_detail_key: '',
                order_sqlite_id: orderId,
                order_id: '0',
                order_key: orderKey,
                tax_name: taxList[i].name,
                type: taxList[i].type,
                rate: taxList[i].tax_rate,
                tax_id: taxList[i].tax_id.toString(),
                branch_link_tax_id:
                    branchTaxData[0].branch_link_tax_id.toString(),
                tax_amount: taxList[i].tax_amount!.toStringAsFixed(2),
                sync_status: 0,
                created_at: dateTime,
                updated_at: '',
                soft_delete: ''));
        OrderTaxDetail returnData =
            await insertOrderTaxDetailKey(data, dateTime);
        _value.add(jsonEncode(returnData));
      }
    }
    order_tax_value = _value.toString();
  }

  updateOrderDetail(String dateTime) async {
    try {
      for(var item in itemList){
        OrderDetail thisOrderDetail = await PosDatabase.instance.readSpecificOrderDetailByLocalIdNoJoin(item.order_detail_sqlite_id!);
        OrderDetail orderDetailObject = OrderDetail(
            promo: item.promo,
            charge: item.charge,
            tax: item.tax,
            sync_status: thisOrderDetail.sync_status == 0 ? 0 : 2,
            updated_at: dateTime,
            order_detail_sqlite_id: int.parse(item.order_detail_sqlite_id!)
        );
        await PosDatabase.instance.updateOrderDetailJson(orderDetailObject);
      }
    } catch(e) {
      FLog.error(
        className: "make_payment_dialog",
        text: "updateOrderDetail error",
        exception: "$e",
      );
    }
  }

  readSpecificPaymentMethod() async {
    List<PaymentLinkCompany> data = await PosDatabase.instance
        .readPaymentMethodByType(_type.toString());
    if (data.length > 0) {
      ipay_code = data[0].ipay_code!;
    }
  }

  readAllOrder() async {
    List<Order> data = await PosDatabase.instance.readLatestOrder();
    orderList = List.from(data);
  }

  syncAllToCloud() async {
    try {
      if (mainSyncToCloud.count == 0) {
        mainSyncToCloud.count = 1;
        final prefs = await SharedPreferences.getInstance();
        final int? device_id = prefs.getInt('device_id');
        final String? login_value = prefs.getString('login_value');
        Map data = await Domain().syncLocalUpdateToCloud(
            device_id: device_id.toString(),
            value: login_value,
            order_value: this.order_value,
            order_promotion_value: this.order_promotion_value,
            order_tax_value: this.order_tax_value);
        if (data['status'] == '1') {
          List responseJson = data['data'];
          for (int i = 0; i < responseJson.length; i++) {
            switch (responseJson[i]['table_name']) {
              case 'tb_order':
                {
                  await PosDatabase.instance.updateOrderSyncStatusFromCloud(
                      responseJson[i]['order_key'], responseJson[i]['updated_at']);
                }
                break;
              case 'tb_order_promotion_detail':
                {
                  await PosDatabase.instance
                      .updateOrderPromotionDetailSyncStatusFromCloud(
                          responseJson[i]['order_promotion_detail_key']);
                }
                break;
              case 'tb_order_tax_detail':
                {
                  await PosDatabase.instance
                      .updateOrderTaxDetailSyncStatusFromCloud(
                          responseJson[i]['order_tax_detail_key']);
                }
                break;
              default:
                {
                  return;
                }
            }
          }
          mainSyncToCloud.resetCount();
        } else if (data['status'] == '7') {
          mainSyncToCloud.resetCount();
          this.isLogOut = true;
        } else if (data['status'] == '8') {
          print('payment time out');
          mainSyncToCloud.resetCount();
          throw TimeoutException("Timeout");
        } else {
          mainSyncToCloud.resetCount();
        }
      }
      // bool _hasInternetAccess = await Domain().isHostReachable();
      // if (_hasInternetAccess) {
      //
      // }
    } catch (e) {
      print('make payment sync to cloud error ${e}');
      mainSyncToCloud.resetCount();
    }
  }

  checkDeviceLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? device_id = prefs.getInt('device_id');
      final String? login_value = prefs.getString('login_value');
      Map data = await Domain().checkDeviceLogin(
          device_id: device_id.toString(), value: login_value);
      if (data['status'] == '1') {
        this.isLogOut = false;
      } else if (data['status'] == '7') {
        this.isLogOut = true;
      } else if (data['status'] == '8') {
        throw TimeoutException("Timeout");
      }
    } catch (e) {
      Navigator.of(context).pop();
    }
    // bool _hasInternetAccess = await Domain().isHostReachable();
    // if (_hasInternetAccess) {
    //
    // }
  }

/*
  -------------------API Call---------------------------------------------------------------------------------------------------------------------------------------------------------
*/

  paymentApi() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    String refKey = branch_id.toString() + DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    try{
      var response = await Api().sendPayment(
          branchObject['ipay_merchant_code'],
          branchObject['ipay_merchant_key'],
          336,
          refKey!,
          Utils.formatPaymentAmount(double.parse(finalAmount)),
          'MYR',
          'ipay',
          branchObject['name'],
          branchObject['email'],
          branchObject['phone'],
          'remark',
          result!.code!,
          '',
          '',
          '',
          '',
          signature256(
              branchObject['ipay_merchant_key'],
              branchObject['ipay_merchant_code'],
              refKey!,
              finalAmount,
              //need to change to finalAmount
              'MYR',
              '',
              result!.code!,
              ''));
      return response;
    }catch(e){
      assetsAudioPlayer.open(
        Audio("audio/error_sound.mp3"),
      );
      FLog.error(
        className: "make_payment_dialog",
        text: "paymentApi error",
        exception: "$e",
      );
      return {
        'status': '0',
        'data': e
      };
    }
  }

  signature256(var merchant_key, var merchant_code, var refNo, var amount, var currency, var xFields, var barcodeNo, var TerminalId) {
    var ipayAmount = double.parse(amount) * 100;
    print("ipay amount: ${ipayAmount.toStringAsFixed(0)}");
    var signature = utf8.encode(merchant_key +
        merchant_code +
        refNo +
        ipayAmount.toStringAsFixed(0) +
        currency +
        xFields +
        barcodeNo +
        TerminalId);
    String value = sha256.convert(signature).toString();
    return value;
  }

  calcChange(String amount) {
    try {
      if (amount != '' && double.parse(amount) >= double.parse(finalAmount)) {
        double value = double.parse(amount) - double.parse(finalAmount);
        setState(() {
          change = value.toStringAsFixed(2);
        });
      } else {
        setState(() {
          change = '0.00';
        });
      }
    } catch (e) {
      change = '0.00';
    }
  }

  void makePayment() async {
    if (inputController.text.isNotEmpty && double.parse(inputController.text) >= double.parse(finalAmount)) {
      setState(() {
        willPop = false;
        isButtonDisable = true;
      });
      asyncQ.addJob((_) async {
        try{
          await callCreateOrder(inputController.text, orderChange: change);
          // await callCreateOrder(inputController.text, orderChange: change);
          if (this.isLogOut == true) {
            openLogOutDialog();
            return;
          }
          await openPaymentSuccessDialog(widget.dining_id, split_payment, isCashMethod: true, diningName: widget.dining_name);
          Branch? data = await PosDatabase.instance.readLocalBranch();
          if(data != null && data.allow_livedata == 1){
            if(!isSyncisSyncingingNotifier.value){
              isSyncisSyncingingNotifier.value = true;
              do{
                await syncToCloud.syncAllToCloud(isManualSync: true);
              }while(syncToCloud.emptyResponse == false);
              if(syncToCloud.emptyResponse == true){
                isSyncisSyncingingNotifier.value = false;
              }
            }
          }
        }catch(e){
          print("error: $e");
        }
      });
    } else if (inputController.text.isEmpty) {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('please_enter_an_amount'));
      setState(() {
        inputController.clear();
      });
    } else {
      Fluttertoast.showToast(
          backgroundColor: Color(0xFFFF0000),
          msg: AppLocalizations.of(context)!.translate('insufficient_balance'));
      setState(() {
        inputController.clear();
      });
    }
  }

  readPaymentMethod() async {
    //read available payment method
    List<PaymentLinkCompany> data = await PosDatabase.instance.readPaymentMethods();
    PaymentLists = List.from(data);
    setState(() {
      isload = true;
    });
  }

  getAllPaymentSplit(String order_key) async {
    try {
      paymentSplitList = [];
      paymentSplitAmount = 0.0;
      if(order_key != '') {
        List<OrderPaymentSplit> orderSplit = await PosDatabase.instance.readSpecificOrderSplitByOrderKey(order_key);
        for(int k = 0; k < orderSplit.length; k++){
          paymentSplitAmount += double.parse(orderSplit[k].amount!);
          paymentSplitList.add(orderSplit[k]);
        }
      }
    } catch(e) {
      print("Total payment split error: $e");
    }
  }
}
