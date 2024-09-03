import 'dart:convert';
import 'dart:io';

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
  String value = "init", imagePath = '';
  FileImage? paymentImg;
  List<FileImage> imageList = [];
  SecondDisplayData? obj;
  late SharedPreferences prefs;
  bool isLoaded = false, bannerLoaded = false, paymentImgLoaded = false;

  @override
  void initState() {
    initBanner();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SecondaryDisplay(
          callback: (argument) async {
            try{
              switch(argument){
                case "init": {
                  setState(() {
                    value = argument;
                  });
                }break;
                case "refresh_img": {
                  await initBanner();
                }break;
                default: {
                  var decode = jsonDecode(argument);
                  obj = SecondDisplayData.fromJson(decode);
                  await initPaymentImage(secondDisplayData: obj!);
                  setState(() {
                    value = argument;
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
                value == "init";
              });
            }
          },
          child: value == "init" && bannerLoaded == true ?
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
              Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("drawable/login_background.jpg"),
                      fit: BoxFit.cover,
                    )
                ),
                child: Center(
                    child: Column(
                      children: [
                        Container(
                            height: 150,
                            child: Image(image: AssetImage("drawable/logo.png"),)
                        ),
                      ],
                    )
                ),
              ) :
          obj != null && paymentImgLoaded ?
          Container(
            color: Colors.white24,
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("drawable/login_background.jpg"),
                            fit: BoxFit.cover,
                          )
                      ),
                      child: Column(
                        children: [
                          Container(
                              height: 150,
                              child: Image(image: AssetImage("drawable/logo.png"))
                          ),
                          paymentImg != null ?
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                                height: 200,
                                child: Image(image: paymentImg!)
                            ),
                          )
                              :
                              Container(),
                        ],
                      ),
                    )
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.translate('table_no')+': ${obj?.tableNo}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                              itemCount: obj!.itemList!.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  height: 20,
                                  child: ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                                    title: Text('${obj!.itemList![index].product_name} ${getVariant(obj!.itemList![index])}'),
                                    leading: Text('${obj!.itemList![index].quantity}'),
                                    trailing: Text('${obj!.itemList![index].price!}/${obj!.itemList![index].per_quantity_unit!}${getProductUnit(obj!.itemList![index])}'),
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
                                        Text(AppLocalizations.of(context)!.translate('subtotal')+': ${obj?.subtotal}', style: TextStyle(fontSize: 12)),
                                        SizedBox(height: 5),
                                        Text(AppLocalizations.of(context)!.translate('total_discount')+': ${obj?.totalDiscount}', style: TextStyle(fontSize: 12))
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
                                        Text(AppLocalizations.of(context)!.translate('total_tax')+': ${obj?.totalTax}', style: TextStyle(fontSize: 12)),
                                        SizedBox(height: 5),
                                        Text(AppLocalizations.of(context)!.translate('rounding')+': ${obj?.rounding}', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  )
                                )
                            )
                          ],
                        ),
                        Expanded(
                            child: Card(
                              elevation: 10,
                              child: Container(
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.all(5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Total Amount: ${obj?.finalAmount}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  ],
                                )
                              ),
                            )
                        )
                      ],
                    ),

                  )
                ),
              ],
            )
          )
              :
          CustomProgressBar()
      ),
    );
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
        //if pref did not have folder path
        await _createBannerImgFolder();
        await getBanner();
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

  _createBannerImgFolder() async {
    final folderName = 'banner';
    final directory = await _localPath;
    final path = '$directory/assets/$folderName';
    final pathImg = Directory(path);
    pathImg.create();
    await prefs.setString('banner_path', path);
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
