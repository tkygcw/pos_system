import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WinDisplayFunction {
  static final WinDisplayFunction instance = WinDisplayFunction._init();

  WinDisplayFunction._init();

  Future<void> transferDataToDisplayWindows(String method, {String? arguments}) async {
    try{
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final windowId in subWindowIds) {
        DesktopMultiWindow.invokeMethod(
          windowId,
          method,
          arguments,
        );
      }
    }catch(e, s){
      FLog.error(
        className: "WinDisplayFunction",
        text: "transferDataToDisplayWindows error",
        exception: 'Error: $e, StackTrace: $s',
      );
    }
  }

  Future<void> refreshCusDisplayImg() async {
    var prefs = await SharedPreferences.getInstance();
    var path = prefs.getString('banner_path');
    await transferDataToDisplayWindows('refresh_img', arguments: path ?? '');
  }

  Future<void> closeAllSubWindows() async {
    try{
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final windowId in subWindowIds) {
        WindowController.fromWindowId(windowId).close();
      }
    }catch(e, s){
      FLog.error(
        className: "WinDisplayFunction",
        text: "closeAllSubWindows error",
        exception: 'Error: $e, StackTrace: $s',
      );
    }
  }
}