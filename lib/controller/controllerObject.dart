import 'dart:async';

class ControllerClass{
  StreamController productOrderDialogController = StreamController();
  StreamController appDeviceController = StreamController();
  StreamController hardwareSettingController = StreamController();
  StreamController orderSettingController = StreamController();
  StreamController editProductController = StreamController();
  late Stream hardwareSettingStream = hardwareSettingController.stream.asBroadcastStream();
  late Stream orderSettingStream = hardwareSettingController.stream.asBroadcastStream();
  late Stream appDeviceStream = appDeviceController.stream.asBroadcastStream();
  late Stream productOrderDialogStream = productOrderDialogController.stream.asBroadcastStream();

  refresh(StreamController streamController){
    streamController.sink.add("refresh");
  }
}