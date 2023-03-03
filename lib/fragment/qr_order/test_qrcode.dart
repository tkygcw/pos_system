import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';

class TestQrcode extends StatefulWidget {
  const TestQrcode({Key? key}) : super(key: key);

  @override
  State<TestQrcode> createState() => _TestQrcodeState();
}

class _TestQrcodeState extends State<TestQrcode> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: QrImageView(
            data: 'https://pos.lkmng.com/app/dashboard/setting',
            embeddedImage: FileImage(File('/data/data/com.example.pos_system/files/assets/img/logo1.jpg')),
            embeddedImageEmitsError: false,
            padding: EdgeInsets.all(150),
            eyeStyle: QrEyeStyle(color: Colors.pink),
            dataModuleStyle: QrDataModuleStyle(color: Colors.purple, dataModuleShape: QrDataModuleShape.square),
            embeddedImageStyle: QrEmbeddedImageStyle(size: Size(50, 50)),
        ),
      ),
    );
  }
}
