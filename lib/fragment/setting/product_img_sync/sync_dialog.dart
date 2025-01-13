import 'package:flutter/material.dart';
import 'package:pos_system/database/pos_database.dart';
import 'package:pos_system/object/product.dart';
import 'package:pos_system/page/progress_bar.dart';

class ProductImgSyncDialog extends StatefulWidget {
  const ProductImgSyncDialog({Key? key}) : super(key: key);

  @override
  State<ProductImgSyncDialog> createState() => _ProductImgSyncDialogState();
}

class _ProductImgSyncDialogState extends State<ProductImgSyncDialog> {
  final _posDatabase = PosDatabase.instance;
  late Future<List<Product>> _readBranchProduct;

  Future<List<Product>> readBranchProduct() async {
    throw 'self error';
    return await _posDatabase.readAllProduct();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _readBranchProduct = readBranchProduct();

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Sync product image"),
      content: FutureBuilder(
        future: _readBranchProduct,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
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
              return Placeholder();
            }
          }
        },
      ),
    );
  }
}
