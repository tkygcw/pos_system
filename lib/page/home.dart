import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pos_system/fragment/bill/bill.dart';
import 'package:pos_system/fragment/cart/cart.dart';
import 'package:pos_system/fragment/order/order.dart';
import 'package:pos_system/fragment/product/product.dart';
import 'package:pos_system/fragment/setting/setting.dart';
import 'package:pos_system/fragment/settlement/settlement_page.dart';
import 'package:pos_system/fragment/table/table.dart';
import 'package:pos_system/main.dart';
import 'package:pos_system/notifier/theme_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/pos_database.dart';
import '../fragment/display_order/other_order.dart';
import '../fragment/logout_dialog.dart';
import '../fragment/qr_order/qr_order_page.dart';
import '../fragment/report/init_report_page.dart';
import '../fragment/settlement/cash_dialog.dart';
import '../object/app_setting.dart';
import '../object/branch.dart';
import '../object/user.dart';

//11
class HomePage extends StatefulWidget {
  final User? user;
  final bool isNewDay;

  const HomePage({Key? key, this.user, required this.isNewDay}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CollapsibleItem> _items;
  late String currentPage;
  late String role;
  String? branchName;
  Timer? timer, notificationTimer;
  bool hasNotification = false;
  int loaded = 0;
  late ThemeColor themeColor;
  List<AppSetting> appSettingList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(notificationModel.notificationStarted == false){
      setupFirebaseMessaging();
    }
    initSecondDisplay();
    _items = _generateItems;
    currentPage = 'menu';
    getRoleName();
    getBranchName();
    if (widget.isNewDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return WillPopScope(child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true), onWillPop: () async => false);
              //CashDialog(isCashIn: true, callBack: (){}, isCashOut: false, isNewDay: true,);
            });
      });
    }
    setScreenLayout();
  }

  @override
  dispose() {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeRight,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);

    if (notificationTimer != null) {
      notificationTimer!.cancel();
    }

    super.dispose();
  }

  initSecondDisplay() async {
    if(notificationModel.hasSecondScreen == true){
      await displayManager.showSecondaryDisplay(displayId: notificationModel.displays[1]!.displayId, routerName: "presentation");
    }
  }

  setScreenLayout() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // final double screenHeight = WidgetsBinding
    //     .instance.platformDispatcher.views.first.physicalSize.height /
    //     WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    // if (screenHeight < 500) {
    //   SystemChrome.setPreferredOrientations([
    //     DeviceOrientation.landscapeLeft,
    //     DeviceOrientation.landscapeRight,
    //   ]);
    // }
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
    var size = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      this.themeColor = color;
      return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              //side nav bar
              child: CollapsibleSidebar(
                  sidebarBoxShadow: [
                    BoxShadow(
                      color: Colors.transparent,
                    ),
                  ],
                  // maxWidth: 80,
                  isCollapsed: true,
                  items: _items,
                  avatarImg: AssetImage("drawable/logo.png"),
                  title: widget.user!.name! + "\n" + (branchName ?? '') + " - " + role,
                  backgroundColor: color.backgroundColor,
                  selectedTextColor: color.iconColor,
                  textStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                  titleStyle: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                  toggleTitleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  selectedIconColor: color.iconColor,
                  selectedIconBox: color.buttonColor,
                  unselectedIconColor: Colors.white,
                  body: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _body(size, context),
                      ),
                      //cart page
                      Visibility(
                        visible: currentPage != 'product' &&
                            currentPage != 'setting' &&
                            currentPage != 'settlement' &&
                            currentPage != 'qr_order' &&
                            currentPage != 'report'
                            ? true
                            : false,
                        child: Expanded(
                            flex: MediaQuery.of(context).size.height > 500 ? 1 : 2,
                            child: CartPage(
                              currentPage: currentPage,
                            )),
                      )
                    ],
                  )),
            )),
      );
    });
  }

  List<CollapsibleItem> get _generateItems {
    return [
      CollapsibleItem(
        text: 'Menu',
        icon: Icons.add_shopping_cart,
        onPressed: () => setState(() => currentPage = 'menu'),
        isSelected: true,
      ),
      CollapsibleItem(
        text: 'Table',
        icon: Icons.table_restaurant,
        onPressed: () => setState(() => currentPage = 'table'),
      ),
      CollapsibleItem(
        text: 'Qr Order',
        icon: Icons.qr_code_2,
        onPressed: () => setState(() => currentPage = 'qr_order'),
      ),
      CollapsibleItem(
        text: 'Other Order',
        icon: Icons.delivery_dining,
        onPressed: () => setState(() => currentPage = 'other_order'),
      ),
      CollapsibleItem(
        text: 'Bill',
        icon: Icons.receipt_long,
        onPressed: () => setState(() => currentPage = 'bill'),
      ),
      CollapsibleItem(
        text: 'Counter',
        icon: Icons.point_of_sale,
        onPressed: () => setState(() => currentPage = 'settlement'),
      ),
      CollapsibleItem(
        text: 'Report',
        icon: Icons.monetization_on,
        onPressed: () => setState(() => currentPage = 'report'),
      ),
      CollapsibleItem(
        text: 'Product',
        icon: Icons.fastfood,
        onPressed: () => setState(() => currentPage = 'product'),
      ),
      CollapsibleItem(
        text: 'Setting',
        icon: Icons.settings,
        onPressed: () => setState(() => currentPage = 'setting'),
      ),
    ];
  }

  Widget _body(Size size, BuildContext context) {
    switch (currentPage) {
      case 'menu':
        return OrderPage();
      case 'product':
        return ProductPage();
      case 'table':
        return TablePage();
      case 'qr_order':
        return QrOrderPage();
      case 'bill':
        return BillPage();
      case 'other_order':
        return OtherOrderPage();
      case 'report':
        return InitReportPage();
      case 'settlement':
        return SettlementPage();
      default:
        return SettingMenu();
    }
  }

  getRoleName() {
    if (widget.user?.role.toString() == "0") {
      role = 'Owner';
    } else if (widget.user!.role! == 1) {
      role = 'Cashier';
    } else if (widget.user!.role! == 2) {
      role = 'Manager';
    } else if (widget.user!.role! == 3) {
      role = 'Waiter';
    }
  }

  getBranchName() async {
    final prefs = await SharedPreferences.getInstance();
    final int? branch_id = prefs.getInt('branch_id');
    Branch? data = await PosDatabase.instance.readBranchName(branch_id.toString());
    setState(() {
      branchName = data!.name!;
    });
    print('branch name : $branchName');
  }

  /*
  *
  *   handle Push notification purpose
  *
  * */
  Future<void> setupFirebaseMessaging() async {
    print('setup firebase called');
    notificationModel.setNotificationAsStarted();
    // Update the iOS foreground notification presentation options to allow
    // heads up notifications.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('has notification');
      showFlutterNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('testing purpose on app open');
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {}
    });
  }

  void showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      /*
      * qr ordering come in
      * */
      if (message.data['type'] == '0') {
        if(qrOrder.count == 0){
          qrOrder.getQrOrder();
          manageNotificationTimer();
          qrOrder.count = 0;
        }
      }
      /*
      * sync request
      * */
      else {
        notificationModel.setNotification(true);
        notificationModel.setContentLoad();
        Fluttertoast.showToast(backgroundColor: Colors.green, msg: "Cloud db change! sync from cloud");
        // await SyncRecord().syncFromCloud();
        if(syncRecord.count == 0){
          await syncRecord.syncFromCloud();
          syncRecord.count = 0;
        }
      }
    }
  }

  manageNotificationTimer() {
    // showSnackBar();
    // playSound();
    //cancel previous timer if new order come in
    if (notificationTimer != null && notificationTimer!.isActive) {
      notificationTimer!.cancel();
    }
    //set timer when new order come in
    int no = 1;
    notificationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (no <= 3) {
        //showSnackBar();
        snackBarKey.currentState!.showSnackBar(SnackBar(
          content: const Text('New order is received!'),
          backgroundColor: themeColor.backgroundColor,
          action: SnackBarAction(
            textColor: themeColor.iconColor,
            label: 'Check it now!',
            onPressed: () {
              if(mounted){
                setState(() {
                  currentPage = 'qr_order';
                  notificationTimer!.cancel();
                });
              }
              no = 3;
            },
          ),
        ));
        playSound();
      } else
        timer.cancel();
      no++;
    });
  }

  showSnackBar() {
    snackBarKey.currentState!.showSnackBar(SnackBar(
      content: const Text('New order is received!'),
      backgroundColor: themeColor.backgroundColor,
      action: SnackBarAction(
        textColor: themeColor.iconColor,
        label: 'Check it now!',
        onPressed: () {
          if(mounted){
            setState(() {
              currentPage = 'qr_order';
              notificationTimer!.cancel();
            });
          }
        },
      ),
    ));
  }

  playSound() {
    final assetsAudioPlayer = AssetsAudioPlayer();
    assetsAudioPlayer.open(
      Audio("audio/notification.mp3"),
    );
  }
}
