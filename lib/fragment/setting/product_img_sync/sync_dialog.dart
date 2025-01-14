import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/domain.dart';

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
    List<Product> productList = await _posDatabase.readAllProduct();
    return productList.where((element) => element.graphic_type == '2' && element.image != '').toList();
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
      title: Text("Sync product image"),
      content: FutureBuilder<List<Product>>(
        future: _readProductImage,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return CustomProgressBar();
          } else {
            if(snapshot.hasError){
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.close),
                style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.all(20)
                ),
              );
            } else {
              return DownloadImgWidget(containImgProduct: snapshot.data!);
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
  StreamController<String> _controller = StreamController();
  late int totalBytes = 0;
  int downloadedBytes = 0;

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
    return StreamBuilder(
      stream: _controller.stream,
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.close),
            style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.all(20)
            ),
          );
        } else {
          if(snapshot.hasData){
            if(downloadedBytes == totalBytes){
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.done),
                style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    // backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.all(20)
                ),
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomProgressBar(),
                  Text("$downloadedBytes/$totalBytes")
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
  downloadProductImage(List<Product> productList) async {
    try {
      String company_id = productList.first.company_id!;
      String path = await generateLocalPath(company_id);
      totalBytes = productList.length;

      for (var product in productList) {
        String url = '${Domain.backend_domain}api/gallery/' + company_id + '/' + product.image!;
        final response = await http.get(Uri.parse(url));
        var localPath = path + '/' + product.image!;
        final imageFile = File(localPath);
        await imageFile.writeAsBytes(response.bodyBytes);
        downloadedBytes++;
        _controller.sink.add('add');
      }
    } catch(e) {
      FLog.error(
        className: "loading",
        text: "downloadProductImage error",
        exception: e,
      );
    }
  }
}

