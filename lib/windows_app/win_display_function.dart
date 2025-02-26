import 'package:desktop_multi_window/desktop_multi_window.dart';

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
      print("error: $e, $s");
    }
  }
}