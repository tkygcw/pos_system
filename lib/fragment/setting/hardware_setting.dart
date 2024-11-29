import 'dart:async';
import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/object/subscription.dart';
import 'package:pos_system/object/table.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_checker/store_checker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/controllerObject.dart';
import '../../database/pos_database.dart';
import '../../main.dart';
import '../../notifier/app_setting_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/app_setting.dart';
import '../../object/receipt.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';

class HardwareSetting extends StatefulWidget {
  const HardwareSetting({Key? key}) : super(key: key);

  @override
  State<HardwareSetting> createState() => _HardwareSettingState();
}

class _HardwareSettingState extends State<HardwareSetting> {
  ControllerClass controller = ControllerClass();
  StreamController actionController = StreamController();
  AppSetting appSetting = AppSetting();
  late StreamController streamController;
  late Stream actionStream;
  Receipt? receiptObject;
  final List<String> sortBy = [
    'default',
    'product_name',
    'product_sku',
    'product_price',
    'product_name_seq_desc',
    'product_sku_seq_desc',
    'product_price_seq_desc'
  ];
  final List<String> variantItemSortBy = [
    'variant_item_name',
    'variant_item_sku',
    'variant_item_name_seq_desc'
  ];
  final List<String> tableModeOption = [
    'table_mode_no_table',
    'table_mode_full_table',
    'table_mode_no_table_special'
  ];
  int? selectedValue = 0;
  int? variantSelectedValue = 0;
  int? tableMode = 0;
  bool cashDrawer = false, secondDisplay = false, directPayment = false, showSKU = false,
      qrOrderAutoAccept = false, showProductDesc = false, hasQrAccess = true;
  String subscriptionEndDate = '', source = "";
  int daysLeft = 0;

  @override
  void initState() {
    super.initState();
    streamController = controller.hardwareSettingController;
    actionStream = actionController.stream.asBroadcastStream();
    listenAction();
    getSubscriptionDate();
    getAppVersion();
  }

  listenAction(){
    actionController.sink.add("init");
    actionStream.listen((event) async {
      switch(event){
        case 'init':{
          await checkStatus();
          await getAllAppSetting();
          await read80mmReceiptLayout();
          controller.refresh(streamController);
        }
        break;
        case 'switch':{
          await updateAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'direct_payment':{
          await updateDirectPaymentAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'show_sku':{
          await updateShowSKUAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'show_pro_desc':{
          await updateShowProDescAppSetting();
          controller.refresh(streamController);
        }
        break;
        case 'prod_sort_by':{
          await updateProductSortBySetting();
          controller.refresh(streamController);
        }
        break;
        case 'variant_item_sort_by':{
          await updateVariantItemSortBySetting();
          controller.refresh(streamController);
        }
        break;
      }
    });
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    if(branchObject['qr_order_status'] == '1'){
      hasQrAccess = false;
    }
  }

  read80mmReceiptLayout() async {
    Receipt? data = await PosDatabase.instance.readSpecificReceipt("80");
    if(data != null){
      receiptObject = data;
    }
  }

  getAllAppSetting() async {
    AppSetting? data = await PosDatabase.instance.readAppSetting();
    if(data != null){
      appSetting = data;
      if(appSetting.open_cash_drawer == 1){
        this.cashDrawer = true;
      } else {
        this.cashDrawer = false;
      }

      if(appSetting.show_second_display == 1){
        this.secondDisplay = true;
      } else {
        this.secondDisplay = false;
      }

      if(appSetting.table_order != null) {
        tableMode = appSetting.table_order!;
      }

      if(appSetting.direct_payment == 1){
        this.directPayment = true;
      } else {
        this.directPayment = false;
      }

      if(appSetting.show_sku == 1){
        this.showSKU = true;
      } else {
        this.showSKU = false;
      }

      if(appSetting.show_product_desc == 1){
        this.showProductDesc = true;
      } else {
        this.showProductDesc = false;
      }

      if(appSetting.product_sort_by != null){
        selectedValue = appSetting.product_sort_by!;
      }

      if(appSetting.variant_item_sort_by != null){
        variantSelectedValue = appSetting.variant_item_sort_by!;
      }
    }
  }

  isSmallScreenPortrait() {
    if(MediaQuery.of(context).orientation == Orientation.portrait)
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child) {
        return Scaffold(
            appBar:  MediaQuery.of(context).size.width < 800 && MediaQuery.of(context).orientation == Orientation.portrait ? AppBar(
                elevation: 1,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: color.buttonColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                backgroundColor: Colors.white,
                title: Text(AppLocalizations.of(context)!.translate('general_setting'),
                    style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                centerTitle: false,
            )
            : null,
            body: StreamBuilder(
                stream: controller.hardwareSettingStream,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Card(
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Optimy Pos License v$appVersionCode ($source)',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${AppLocalizations.of(context)!.translate('active_until')} $subscriptionEndDate',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text('$daysLeft ${AppLocalizations.of(context)!.translate('days')}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20
                                  )
                              ),
                            ),
                            color: daysLeft < 7 ? Colors.red : Colors.green,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('open_backend')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('open_backend_desc')),
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final String? branch = prefs.getString('branch');
                              Map branchObject = json.decode(branch!);
                              final branchID = branchObject['branchID'];
                              final branchUrl = branchObject['branch_url'];
                              launchUrl(
                                Uri.parse('https://cp.optimy.com.my?u=$branchUrl&b=$branchID'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('auto_open_cash_drawer')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('auto_open_cash_drawer_after_insert_opening_balance')),
                            trailing: Switch(
                              value: this.cashDrawer,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                this.cashDrawer = value;
                                actionController.sink.add("switch");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('enable_Second_display')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('show_device_second_display')),
                            trailing: Switch(
                              value: this.secondDisplay,
                              activeColor: color.backgroundColor,
                              onChanged: (value) async {
                                if(notificationModel.hasSecondScreen == false){
                                  Fluttertoast.showToast(msg: "${AppLocalizations.of(context)?.translate('no_second_display')}");
                                  return;
                                }
                                this.secondDisplay = value;
                                actionController.sink.add("switch");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('reset_second_display')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('reset_second_display_desc')),
                            trailing: ElevatedButton(
                                onPressed: () async {
                                  await displayManager.transferDataToPresentation("init");
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: color.backgroundColor
                                ),
                                child: Icon(Icons.reset_tv))
                          ),

                          Divider(
                            color: Colors.grey,
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('show_sku')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('show_sku_desc')),
                            trailing: Switch(
                              value: showSKU,
                              activeColor: color.backgroundColor,
                              onChanged: (value) {
                                showSKU = value;
                                appSettingModel.setShowSKUStatus(showSKU);
                                actionController.sink.add("show_sku");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('show_product_desc')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('show_product_desc_desc')),
                            trailing: Switch(
                              value: showProductDesc,
                              activeColor: color.backgroundColor,
                              onChanged: (value) {
                                showProductDesc = value;
                                appSettingModel.setShowProductDescStatus(showProductDesc);
                                actionController.sink.add("show_pro_desc");
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('product_sort_by')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('product_sort_by_desc')),
                            trailing: SizedBox(
                              width: MediaQuery.of(context).orientation == Orientation.landscape ? 200 : 150,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 55,
                                    // padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                        thickness: WidgetStateProperty.all(5),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 5
                                    ),
                                  ),
                                  items: sortBy.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                    value: sort.key,
                                    child: Text(
                                      AppLocalizations.of(context)!.translate(sort.value),
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: selectedValue,
                                  onChanged: (int? value) {
                                    selectedValue = value;
                                    actionController.sink.add("prod_sort_by");
                                    Provider.of<AppSettingModel>(context, listen: false).setProductSortByStatus(value!);
                                  },
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.translate('variant_item_sort_by')),
                            subtitle: Text(AppLocalizations.of(context)!.translate('variant_item_sort_by_desc')),
                            trailing: SizedBox(
                              width: MediaQuery.of(context).orientation == Orientation.landscape ? 200 : 150,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2(
                                  isExpanded: true,
                                  buttonStyleData: ButtonStyleData(
                                    height: 55,
                                    // padding: const EdgeInsets.only(left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade100,
                                    ),
                                    scrollbarTheme: ScrollbarThemeData(
                                        thickness: WidgetStateProperty.all(5),
                                        mainAxisMargin: 20,
                                        crossAxisMargin: 5
                                    ),
                                  ),
                                  items: variantItemSortBy.asMap().entries.map((sort) => DropdownMenuItem<int>(
                                    value: sort.key,
                                    child: Text(
                                      AppLocalizations.of(context)!.translate(sort.value),
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  )).toList(),
                                  value: variantSelectedValue,
                                  onChanged: (int? value) {
                                    variantSelectedValue = value;
                                    actionController.sink.add("variant_item_sort_by");
                                    Provider.of<AppSettingModel>(context, listen: false).setVariantItemSortByStatus(value!);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return CustomProgressBar();
                  }
                }
            )

        );
      });
    });
  }

  updateAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        open_cash_drawer: this.cashDrawer == true ? 1 : 0,
        show_second_display: this.secondDisplay == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        table_order: this.tableMode,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateAppSettings(object);
    if(object.show_second_display == 0){
      notificationModel.disableSecondDisplay();
    } else {
      notificationModel.enableSecondDisplay();
    }
  }

  updateDirectPaymentAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        direct_payment: this.directPayment == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateDirectPaymentSettings(object);
  }

  updateShowSKUAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        show_sku: this.showSKU == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateShowSKUSettings(object);
  }

  updateShowProDescAppSetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        show_product_desc: showProductDesc == true ? 1 : 0,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateShowProDescSettings(object);
  }

  updateProductSortBySetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        product_sort_by: selectedValue,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateProductSortBySettings(object);
  }

  updateVariantItemSortBySetting() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateTime = dateFormat.format(DateTime.now());
    AppSetting object = AppSetting(
        variant_item_sort_by: variantSelectedValue,
        app_setting_sqlite_id: appSetting.app_setting_sqlite_id,
        updated_at: dateTime
    );
    int data = await PosDatabase.instance.updateVariantItemSortBySettings(object);
  }

  Future<bool> anyTableUse() async {
    List<PosTable> tableList = await PosDatabase.instance.readAllTable();
    for (int i = 0; i < tableList.length; i++) {
      if(tableList[i].status == 1)
        return true;
    }
    return false;
  }

  getSubscriptionDate() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd");
    Subscription? data = await PosDatabase.instance.readAllSubscription();
    DateTime subscriptionEnd = dateFormat.parse(data!.end_date!);
    Duration difference = subscriptionEnd.difference(DateTime.now());
    setState(() {
      subscriptionEndDate = DateFormat("dd/MM/yyyy").format(subscriptionEnd);
      daysLeft = difference.inDays +1;
    });
  }

  getAppVersion() async {
    Source installationSource;
    try {
      installationSource = await StoreChecker.getSource;
    } on PlatformException {
      installationSource = Source.UNKNOWN;
    }

    switch (installationSource) {
      case Source.IS_INSTALLED_FROM_PLAY_STORE:
      // Installed from Play Store
        source = "Play Store";
        break;
      case Source.IS_INSTALLED_FROM_PLAY_PACKAGE_INSTALLER:
      // Installed from Google Package installer
        source = "Google Package installer";
        break;
      case Source.IS_INSTALLED_FROM_LOCAL_SOURCE:
      // Installed using adb commands or side loading or any cloud service
        source = "Local Source";
        break;
      case Source.IS_INSTALLED_FROM_AMAZON_APP_STORE:
      // Installed from Amazon app store
        source = "Amazon Store";
        break;
      case Source.IS_INSTALLED_FROM_HUAWEI_APP_GALLERY:
      // Installed from Huawei app store
        source = "Huawei App Gallery";
        break;
      case Source.IS_INSTALLED_FROM_SAMSUNG_GALAXY_STORE:
      // Installed from Samsung app store
        source = "Samsung Galaxy Store";
        break;
      case Source.IS_INSTALLED_FROM_SAMSUNG_SMART_SWITCH_MOBILE:
      // Installed from Samsung Smart Switch Mobile
        source = "Samsung Smart Switch Mobile";
        break;
      case Source.IS_INSTALLED_FROM_XIAOMI_GET_APPS:
      // Installed from Xiaomi app store
        source = "Xiaomi Get Apps";
        break;
      case Source.IS_INSTALLED_FROM_OPPO_APP_MARKET:
      // Installed from Oppo app store
        source = "Oppo App Market";
        break;
      case Source.IS_INSTALLED_FROM_VIVO_APP_STORE:
      // Installed from Vivo app store
        source = "Vivo App Store";
        break;
      case Source.IS_INSTALLED_FROM_RU_STORE:
      // Installed apk from RuStore
        source = "RuStore";
        break;
      case Source.IS_INSTALLED_FROM_OTHER_SOURCE:
      // Installed from other market store
        source = "Other Source";
        break;
      case Source.IS_INSTALLED_FROM_APP_STORE:
      // Installed from app store
        source = "App Store";
        break;
      case Source.IS_INSTALLED_FROM_TEST_FLIGHT:
      // Installed from Test Flight
        source = "Test Flight";
        break;
      case Source.UNKNOWN:
      // Installed from Unknown source
        source = "Unknown Source";
        break;
    }
  }
}
