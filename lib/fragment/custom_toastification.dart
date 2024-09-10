import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CustomToastification{
  static showToastification({
    required BuildContext context,
    required String title,
    String? description,
    ToastificationType? type,
  }){
    toastification.show(
      context: context,
      title: title,
      description: description,
      autoCloseDuration: Duration(milliseconds: 2500),
      showProgressBar: false,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      backgroundColor: Colors.redAccent,
      boxShadow: [],
    );
  }
}