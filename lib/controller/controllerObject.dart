import 'dart:async';

class ControllerClass{
  StreamController productOrderDialogController = StreamController();
  StreamController appDeviceController = StreamController();
  late Stream appDeviceStream = appDeviceController.stream.asBroadcastStream();
  late Stream productOrderDialogStream = productOrderDialogController.stream.asBroadcastStream();

  refresh(StreamController streamController){
    streamController.sink.add("refresh");
  }
}