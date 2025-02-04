import 'dart:async';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:http/http.dart' as http;

import '../../../database/domain.dart';
import '../../../translation/AppLocalizations.dart';

enum ButtonType {
  success,
  failed
}

class ProductImgSyncDialog extends StatefulWidget {
  const ProductImgSyncDialog({Key? key}) : super(key: key);

  @override
  State<ProductImgSyncDialog> createState() => _ProductImgSyncDialogState();
}

class _ProductImgSyncDialogState extends State<ProductImgSyncDialog> {
  final _posDatabase = PosDatabase.instance;
  late Future<List<Product>> _readProductImage;
  late String company_id;

  Future<List<Product>> readBranchProduct() async {
    try{
      List<Product> productList = await _posDatabase.readAllProduct();
      return productList.where((element) => element.graphic_type == '2' && element.image != '').toList();
    } catch(e, s){
      FLog.error(
        className: "product img sync dialog",
        text: "readBranchProduct error",
        exception: "Error: $e, StackTarace: $s",
      );
      rethrow;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _readProductImage = readBranchProduct();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('sync_product_image')),
      content: FutureBuilder<List<Product>>(
        future: _readProductImage,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return CustomProgressBar();
          } else {
            if(snapshot.hasError){
              return SyncCompleteButton(buttonType: ButtonType.failed);
            } else {
              if(snapshot.data!.isNotEmpty){
                return DownloadImgWidget(containImgProduct: snapshot.data!);
              } else {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SyncCompleteButton(buttonType: ButtonType.failed),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(AppLocalizations.of(context)!.translate('no_product_image')),
                    )
                  ],
                );
              }
            }
          }
        },
      ),
    );
  }
}

class DownloadImgWidget extends StatefulWidget {
  final List<Product> containImgProduct;
  const DownloadImgWidget({Key? key, required this.containImgProduct}) : super(key: key);

  @override
  State<DownloadImgWidget> createState() => _DownloadImgWidgetState();
}

class _DownloadImgWidgetState extends State<DownloadImgWidget> {
  StreamController<int> _controller = StreamController();
  late int totalBytes = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    downloadProductImage(widget.containImgProduct);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _controller.stream,
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return SyncCompleteButton(buttonType: ButtonType.failed);
        } else {
          if(snapshot.hasData){
            if(snapshot.data == totalBytes){
              return SyncCompleteButton(buttonType: ButtonType.success);
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomProgressBar(),
                  Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text("${snapshot.data}/$totalBytes"),
                  )
                ],
              );
            }
          } else {
            return CustomProgressBar();
          }
        }
      },
    );
  }

  Future<String> generateLocalPath(String folderName) async {
    final directory = await getApplicationSupportDirectory();
    return '${directory.path}/assets/$folderName';
  }

/*
  download product image
*/
  Future<void> downloadProductImage(List<Product> productList) async {
    int downloadedBytes = 0;
    try {
      String company_id = productList.first.company_id!;
      String path = await generateLocalPath(company_id);
      totalBytes = productList.length;

      for (var product in productList) {
        String url = '${Domain.backend_domain}api/gallery/' + company_id + '/' + product.image!;
        final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 2));
        if(response.bodyBytes.isNotEmpty){
          var localPath = path + '/' + product.image!;
          final imageFile = File(localPath);
          await imageFile.writeAsBytes(response.bodyBytes);
        }
        downloadedBytes++;
        _controller.sink.add(downloadedBytes);
      }
    } catch(e, s) {
      FLog.error(
        className: "product img sync dialog",
        text: "downloadProductImage error",
        exception: "Error: $e, StackTarace: $s",
      );
      _controller.sink.addError(e, s);
    }
  }
}

class SyncCompleteButton extends StatefulWidget {
  final ButtonType buttonType;
  const SyncCompleteButton({Key? key, required this.buttonType}) : super(key: key);

  @override
  State<SyncCompleteButton> createState() => _SyncCompleteButtonState();
}

class _SyncCompleteButtonState extends State<SyncCompleteButton> {
  bool buttonDisable = false;

  @override
  Widget build(BuildContext context) {
    return closeButton;
  }

  ElevatedButton get closeButton {
    if(widget.buttonType == ButtonType.success) {
      return ElevatedButton(
        onPressed: buttonDisable ? null : () {
          buttonDisable = true;
          Navigator.of(context).pop();
        },
        child: Icon(Icons.done),
        style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(20)
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: buttonDisable ? null : () {
          buttonDisable = true;
          Navigator.of(context).pop();
        },
        child: Icon(Icons.close),
        style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            backgroundColor: Colors.redAccent,
            padding: EdgeInsets.all(20)
        ),
      );
    }
  }
}


