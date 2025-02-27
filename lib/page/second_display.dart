import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/payment_link_company.dart';
import 'package:pos_system/object/second_screen.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:pos_system/translation/AppLocalizations.dart';
import 'package:presentation_displays/secondary_display.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../database/domain.dart';
import '../object/cart_product.dart';
import '../object/second_display_data.dart';
import '../object/variant_group.dart';

class SecondDisplay extends StatefulWidget {
  const SecondDisplay({Key? key}) : super(key: key);

  @override
  State<SecondDisplay> createState() => _SecondDisplayState();
}

class _SecondDisplayState extends State<SecondDisplay> {
  String method = "init", imagePath = '';
  FileImage? paymentImg;
  List<FileImage> imageList = [];
  SecondDisplayData? displayData;
  late SharedPreferences prefs;
  bool isLoaded = false, bannerLoaded = false, paymentImgLoaded = false;

  @override
  void initState() {
    initBanner();
    if(Platform.isWindows){
      DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
        method = call.method;
        switch(call.method){
          case 'display': {
            var json = jsonDecode(call.arguments);
            displayData = SecondDisplayData.fromJson(json);
            await initPaymentImage(secondDisplayData: displayData!);
            setState(() {
              paymentImgLoaded = true;
            });
          }break;
          case 'refresh_img': {
            await initBanner();
          }break;
          default: {
            setState(() {});
          }
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Platform.isWindows ?
      DisplayWidget(context) :
      SecondaryDisplay(
          callback: (argument) async {
            try{
              switch(argument){
                case "init": {
                  setState(() {
                    method = argument;
                  });
                }break;
                case "refresh_img": {
                  await initBanner();
                }break;
                default: {
                  var decode = jsonDecode(argument);
                  displayData = SecondDisplayData.fromJson(decode);
                  await initPaymentImage(secondDisplayData: displayData!);
                  setState(() {
                    method = argument;
                    paymentImgLoaded = true;
                  });
                }
              }
            } catch(e){
              FLog.error(
                className: "second_display",
                text: "SecondaryDisplay callback error",
                exception: e,
              );
              setState(() {
                method == "init";
              });
            }
          },
          child: DisplayWidget(context)
      ),
    );
  }

  Widget DisplayWidget(BuildContext context) {
    bool methodStatus  = (method == "init" || method == "refresh_img");
    return methodStatus && bannerLoaded == true ?
            imageList.isNotEmpty ?
            CarouselSlider(
              items: imageList.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                        width: MediaQuery.of(context).size.width,
                        child: Image(image: item, fit: BoxFit.cover)
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                autoPlay: imageList.length > 1 ? true : false,
                autoPlayInterval: Duration(seconds: 8),
                viewportFraction: 1,
                pageSnapping: false,
              ),
            ) :
            Center(
                child: Container(
                  height: 150,
                    child: Image(image: AssetImage("drawable/logo_cus_display.png"),)
                )
            ) :
        displayData != null && paymentImgLoaded ?
        Row(
          children: [
            Expanded(
                flex: 2,
                child: paymentImg != null ? Column(
                  children: [
                    SizedBox(
                        height: 150,
                        child: Image(image: AssetImage("drawable/logo_cus_display.png"))
                    ),
                    SizedBox(
                        height: 200,
                        child: Image(image: paymentImg!)
                    )
                  ],
                ) :
                Center(
                  child: SizedBox(
                    height: 150,
                    child: Image(image: AssetImage("drawable/logo_cus_display.png"),
                    ),
                  ),
                )
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.translate('table_no')+': ${displayData?.tableNo ?? '-'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        Text(displayData?.selectedOption ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    Card(
                      elevation: 5,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(AppLocalizations.of(context)!.translate('qty')),),
                            Expanded(flex: 4, child: Text(AppLocalizations.of(context)!.translate('item')),),
                            Expanded(flex: 1, child: Text(AppLocalizations.of(context)!.translate('price_unit'))),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: displayData!.itemList!.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              height: 20,
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                                title: Text('${displayData!.itemList![index].product_name} ${getVariant(displayData!.itemList![index])}'),
                                leading: Text('${displayData!.itemList![index].quantity}'),
                                trailing: Text('${displayData!.itemList![index].price!}/${displayData!.itemList![index].per_quantity_unit!}${getProductUnit(displayData!.itemList![index])}'),
                              ),
                            );
                          }
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Card(
                              elevation: 10,
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!.translate('subtotal')+': ${displayData?.subtotal}', style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 5),
                                    Text(AppLocalizations.of(context)!.translate('total_discount')+': ${displayData?.totalDiscount}', style: TextStyle(fontSize: 12))
                                  ],
                                ),
                              )
                            )
                        ),
                        Expanded(
                            child: Card(
                              elevation: 10,
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!.translate('total_tax')+': ${displayData?.totalTax}', style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 5),
                                    Text(AppLocalizations.of(context)!.translate('rounding')+': ${displayData?.rounding}', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              )
                            )
                        )
                      ],
                    ),
                    Card(
                      elevation: 10,
                      child: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.all(10),
                        child: Text('Total Amount: ${displayData?.finalAmount}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30))
                      ),
                    )
                  ],
                ),

              )
            ),
          ],
        )
            :
        CustomProgressBar();
  }

  String getProductUnit(cartProductItem item){
    String unit = '';
    if(item.unit == 'each' || item.unit == 'each_c'){
      unit = 'each';
    } else {
      unit = item.unit!;
    }
    return unit;
  }

  initPaymentImage({required SecondDisplayData secondDisplayData}) async {
    try{
      paymentImg = null;
      if(secondDisplayData.payment_link_company_id != null){
        PaymentLinkCompany? data = await PosDatabase.instance.readSpecificPaymentLinkCompany(secondDisplayData.payment_link_company_id!);
        if(data != null && data.allow_image == 1 && data.image_name != null && data.image_name != ''){
          final folderName = secondDisplayData.payment_link_company_id.toString();
          final directory = await _localPath;
          final path = '$directory/assets/payment_qr/$folderName';
          bool isPathExisted = await Directory(path).exists();
          if(isPathExisted){
            //check is image file exist or not
            if(await FileImage(File(path + '/' + data.image_name!)).file.exists() == true){
              print("Payment qr image found!!!");
              paymentImg = FileImage(File(path + '/' + data.image_name!));
            } else {
              //download payment image
              await _downloadPaymentImage(path, data);
              paymentImg = FileImage(File(path + '/' + data.image_name!));
            }
          } else {
            await _createPaymentQrFolder(paymentLinkCompany: data);
            paymentImg = FileImage(File(path + '/' + data.image_name!));
          }
        }
      }
    }catch(e){
      paymentImg = null;
      FLog.error(
        className: "second_display",
        text: "init payment image error",
        exception: e,
      );
    }

  }

  _createPaymentQrFolder({required PaymentLinkCompany paymentLinkCompany}) async {
    final folderName = 'payment_qr';
    final path = await _localPath;
    final pathPaymentQr = Directory('$path/assets/$folderName');
    bool isPathExisted = await pathPaymentQr.exists();
    if(isPathExisted){
      await _createPaymentImgFolder(paymentLinkCompany: paymentLinkCompany);
    } else {
      await pathPaymentQr.create();
      await _createPaymentImgFolder(paymentLinkCompany: paymentLinkCompany);
    }
  }

  _createPaymentImgFolder({required PaymentLinkCompany paymentLinkCompany}) async {
    final folderName = paymentLinkCompany.payment_link_company_id.toString();
    final directory = await _localPath;
    final path = '$directory/assets/payment_qr/$folderName';
    final pathImg = Directory(path);
    pathImg.create();
    if(paymentLinkCompany.image_name != null && paymentLinkCompany.image_name != ''){
      await _downloadPaymentImage(path, paymentLinkCompany);
    }
  }

  _downloadPaymentImage(String path, PaymentLinkCompany paymentLinkCompany) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      String url = '';
      String paymentLinkCompanyId =  paymentLinkCompany.payment_link_company_id.toString();
      String name = paymentLinkCompany.image_name!;
      url = '${Domain.backend_domain}api/payment_QR/' + userObject['company_id'] + '/' + paymentLinkCompanyId + '/' + name;
      final response = await http.get(Uri.parse(url));
      var localPath = path + '/' + name;
      final imageFile = File(localPath);
      await imageFile.writeAsBytes(response.bodyBytes);
    } catch(e){
      FLog.error(
        className: "second_display",
        text: "download payment image error",
        exception: e,
      );
    }
  }

  initBanner() async {
    try{
      imageList.clear();
      prefs = await getPreferences();
      if(prefs.getString('banner_path') == null){
        //create banner image folder
        bool status = await _createBannerImgFolder();
        //start download banner if status = true
        if(status){
          await getBanner();
        }
        setState(() {
          bannerLoaded = true;
        });
      } else {
        await getBanner();
        setState(() {
          bannerLoaded = true;
        });
      }
    }catch(e){
      FLog.error(
        className: "second_display",
        text: "init banner error",
        exception: e,
      );
      imageList.clear();
      setState(() {
        bannerLoaded = true;
      });
    }
  }

  getBanner() async {
    imagePath = prefs.getString('banner_path')!;
    List<SecondScreen> data = await PosDatabase.instance.readAllNotDeletedSecondScreen();
    if(data.isNotEmpty){
      for(int i = 0; i < data.length; i++){
        //check is image exist or not
        if(await FileImage(File(imagePath + '/' + data[i].name!)).file.exists() == true){
          imageList.add(FileImage(File(imagePath + '/' + data[i].name!)));
        } else {
          await downloadBannerImage(imagePath);
          imageList.add(FileImage(File(imagePath + '/' + data[i].name!)));
        }
      }
    }
  }

  getPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<bool> _createBannerImgFolder() async {
    final folderName = 'banner';
    final directory = await _localPath;
    final path = '$directory/assets/$folderName';
    final pathImg = Directory(path);
    bool isPathExisted = await pathImg.exists();
    if(isPathExisted){
      pathImg.create();
      await prefs.setString('banner_path', path);
    }
    return isPathExisted;
  }

/*
  download banner image
*/
  downloadBannerImage(String path) async {
    try{
      final int? branchId = prefs.getInt('branch_id');
      final String? user = prefs.getString('user');
      Map userObject = json.decode(user!);
      Map data = await Domain().getSecondScreen(branch_id: branchId.toString());
      String url = '';
      String name = '';
      if (data['status'] == '1') {
        List responseJson = data['second_screen'];
        for (var i = 0; i < responseJson.length; i++) {
          name = responseJson[i]['name'];
          if (name != '') {
            url = '${Domain.backend_domain}api/banner/' + userObject['company_id'] + '/' + branchId.toString() + '/' + name;
            final response = await http.get(Uri.parse(url));
            var localPath = path + '/' + name;
            final imageFile = File(localPath);
            await imageFile.writeAsBytes(response.bodyBytes);
          }
        }
      }
    } catch(e){
      FLog.error(
        className: "second_display",
        text: "download banner image error",
        exception: e,
      );
    }
  }

  getVariant(cartProductItem object) {
    List<String?> variant = [];
    String result = '';
    try{
      if(object.productVariantName != '' && object.productVariantName != null){
        result = "(${object.productVariantName!})";
      } else if(object.variant != null) {
        var length = object.variant!.length;
        for (int i = 0; i < length ; i++) {
          VariantGroup group = object.variant![i];
          for (int j = 0; j < group.child!.length; j++) {
            if (group.child![j].isSelected!) {
              variant.add(group.child![j].name!);
              result = '(${variant.toString().replaceAll('[', '').replaceAll(']', '')})'
                  .replaceAll(',', ' |');
              //.replaceAll('|', '\n+')
            }
          }
        }
      }
    }catch(e){
      FLog.error(
        className: "second_display",
        text: "get variant error",
        exception: e,
      );
      result = "";
    }
    return result;
  }
}
