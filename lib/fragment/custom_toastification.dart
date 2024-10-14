import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../main.dart';
import '../translation/AppLocalizations.dart';

class _CustomToastification {

  static final BuildContext context = MyApp.navigatorKey.currentContext!;

  static playReviewSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch (e) {
      print("Play Sound Error: ${e}");
    }
  }

  static showToastificationAndSound({
    required String title,
    Widget? description,
    int? autoCloseDuration = 4,
    bool? showProgressBar = false,
    bool? isError,
    bool? playSound,
    int? playTimes = 1
  }){
    toastification.show(
      type: isError != null ? ToastificationType.error : ToastificationType.success,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      showProgressBar: showProgressBar,
      closeOnClick: true,
      icon: isError != null ? Icon(Icons.cancel_rounded) : Icon(Icons.check_circle_rounded),
      title: Text(title),
      description: description,
      autoCloseDuration: Duration(seconds: autoCloseDuration!),
    );
    if(playSound == true){
      int k = 0;
      while(k < playTimes!){
        if(k == 0){
          playReviewSound();
        } else {
          Future.delayed(Duration(seconds: 3), () => playReviewSound());
        }
        k++;
      }
    }

  }
}

class ShowQRToast extends _CustomToastification {
  static showToast(){
    _CustomToastification.showToastificationAndSound(
        title: AppLocalizations.of(_CustomToastification.context)!.translate('new_qr_order_received'),
        showProgressBar: true,
        playSound: true,
        playTimes: 2,
        autoCloseDuration: 5);
  }
}

class ShowFailedPrintKitchenToast {
  static showToast(){
    _CustomToastification.showToastificationAndSound(
      title: "${AppLocalizations.of(_CustomToastification.context)?.translate('error')}"
          "${AppLocalizations.of(_CustomToastification.context)?.translate('kitchen_printer_timeout')}",
      isError: true,
      playSound: true,
      playTimes: 2,
    );
  }
}

class ShowPlaceOrderFailedToast {
  static showToast(String description){
    _CustomToastification.showToastificationAndSound(
      title: AppLocalizations.of(_CustomToastification.context)!.translate('place_order_failed'),
      description: Text(description),
      isError: true,
      playSound: true,
      playTimes: 2,
    );
  }
}