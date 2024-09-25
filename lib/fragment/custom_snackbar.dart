import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class CustomSnackBar {
  static final CustomSnackBar instance = CustomSnackBar.init();
  final BuildContext _context = MyApp.navigatorKey.currentContext!;

  CustomSnackBar.init();

  playSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch (e) {
      print("Play Sound Error: ${e}");
    }
  }

  getDescription(String? description){
    if(description != null){
      return description;
    } else {
      return '';
    }
  }


  showSnackBar({required String title, required ContentType contentType, String? description, bool? playSound, int? playtime}){
    ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
      padding: EdgeInsets.only(top: 20),
      elevation: 0,
      content: AwesomeSnackbarContent(
          title: title,
          message: getDescription(description),
          contentType: contentType),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: MediaQuery.of(_context).orientation == Orientation.landscape
          ? EdgeInsets.only(bottom: MediaQuery.of(_context).size.height - 120)
          : EdgeInsets.only(bottom: MediaQuery.of(_context).size.height - 220),
    ));
    if(playSound != null && playSound == true){
      int k = 0;
      while(k < playtime!){
        if(k == 0){
          this.playSound();
        } else {
          Future.delayed(Duration(seconds: 3), () => this.playSound());
        }
        k++;
      }
    }
  }
}