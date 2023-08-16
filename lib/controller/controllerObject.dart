import 'dart:async';

class ControllerClass{
  StreamController productOrderDialogController = StreamController();
  late Stream productOrderDialogStream = productOrderDialogController.stream.asBroadcastStream();
}