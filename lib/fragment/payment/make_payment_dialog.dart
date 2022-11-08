import 'package:flutter/material.dart';
import 'package:pos_system/fragment/payment/number_button.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'dart:developer';


class MakePayment extends StatefulWidget {
  const MakePayment({Key? key}) : super(key: key);

  @override
  State<MakePayment> createState() => _MakePamentState();
}

class _MakePamentState extends State<MakePayment> {
  var type ="0";
  var userInput = '';
  var answer = '';
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool scanning=false;
  bool isopen=false;

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {


    // Array of button
    final List<String> buttons = [
      '7',
      '8',
      '9',
      'C',
      '4',
      '5',
      '6',
      'DEL',
      '1',
      '2',
      '3',
      '',
      '00',
      '0',
      '.',
      '',
      '20.00',
      '50.00',
      '100.00',
      'GO',

    ];

    return AlertDialog(
      title: Text('Amount'),
        content: Container(
          width: MediaQuery.of(context).size.width / 1.4,
          height: MediaQuery.of(context).size.height / 1.5,
          child: Row(

            children: [
              Expanded(
                flex: 5,
                child: Container(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(20),
                          alignment: Alignment.centerRight,
                          child: Text(
                            userInput,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(15),
                          alignment: Alignment.centerRight,
                          child: Text(
                            answer,
                            style: TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ]),
                ),
              ),
              Expanded(
                flex: 5,
                child: type=='x'?Container(
                  height:MediaQuery.of(context).size.height / 1.5 ,
                  child: Column(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Container(
                                alignment: AlignmentDirectional.bottomEnd,
                                child: Text(userInput,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 70,
                                    fontWeight: FontWeight.w400,
                                  ),),
                            )

                            ,
                          )
                      ),

                      Expanded(
                        flex: 8,
                        child: GridView.builder(

                            itemCount: buttons.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: MediaQuery.of(context).size.width /
                                (MediaQuery.of(context).size.height / 0.9),),
                            itemBuilder: (BuildContext context, int index) {
                              // Clear Button

                              if (index == 3) {
                              return NumberButton(
                              buttontapped: () {
                              setState(() {
                              userInput =
                              userInput.substring(0, userInput.length - 1);
                              });
                              },
                              buttonText: buttons[index],
                              color: Colors.blue[50],
                              textColor: Colors.black,
                              );
                              }

                              // +/- button
                              else if (index == 7) {
                                return NumberButton(
                                  buttontapped: () {
                                    setState(() {
                                      userInput = '';

                                    });
                                  },
                                  buttonText: buttons[index],
                                  color: Colors.blue[50],
                                  textColor: Colors.black,
                                );
                              }

                              // Delete Button

                              // Equal_to Button
                              else if (index == 16) {
                                return NumberButton(
                                  buttontapped: () {
                                    setState(() {
                                      userInput = buttons[index];

                                    });
                                  },
                                  buttonText: buttons[index],
                                  color: Colors.orange[300],
                                  textColor: Colors.white,
                                );
                              }
                              else if (index == 17) {
                                return NumberButton(
                                  buttontapped: () {
                                    setState(() {
                                      userInput = buttons[index];

                                    });
                                  },
                                  buttonText: buttons[index],
                                  color: Colors.orange[300],
                                  textColor: Colors.white,
                                );
                              }
                              else if (index == 18) {
                                return NumberButton(
                                  buttontapped: () {
                                    setState(() {
                                      userInput = buttons[index];
                                    });
                                  },
                                  buttonText: buttons[index],
                                  color: Colors.orange[300],
                                  textColor: Colors.white,
                                );
                              }
                              else if (index == 19) {
                                return NumberButton(
                                  buttontapped: () {
                                    setState(() {
                                      // equalPressed();
                                    });
                                  },
                                  buttonText: buttons[index],
                                  color: Colors.orange[700],
                                  textColor: Colors.white,
                                );
                              }
                              //  other buttons
                              else {
                                return NumberButton(
                                  buttontapped: () {
                                    setState(() {
                                      userInput += buttons[index];
                                    });
                                  },
                                  buttonText: buttons[index],
                                  color: Colors.white,
                                  textColor:  Colors.black,
                                );
                              }
                            }),
                      ),
                    ],
                  ), // GridView.builder
                ):type=='x'?Container(
                  child: Column(
                    children: [
                      Expanded(
                          flex:6,
                          child: Container(
                            child: ClipRRect(

                              borderRadius:
                              BorderRadius.circular(16.0),
                              child:

                              ///***If you have exported images you must have to copy those images in assets/images directory.
                              Image(
                                image: NetworkImage(
                                    "https://v.icbc.com.cn/userfiles/Resources/ICBC/haiwai/Malaysia/photo/2021/mobil202108034.jpg"),
                                height: MediaQuery.of(context).size.height/2,
                                width: MediaQuery.of(context).size.width/2,
                              ),
                            ),

                          )
                      ),
                      Expanded(
                          flex:1,
                          child: Container(
                            alignment: Alignment.center,
                            child: Text('RM50.00',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold),),
                          )
                      ),
                      Expanded(
                          flex:2,
                          child: Container(
                          alignment: Alignment.center,
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 60,
                              child: ElevatedButton(

                                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green) ),
                                onPressed: () {

                              }, child: Text("Comfirm",style:TextStyle(fontSize: 25)),

                              ),
                            ),
                          )
                      ),
                      Expanded(flex: 1,child: Container(),)
                    ],
                  ) ,
                ):type=='0'?Container(
                    child: Column(
                      children: [
                        Expanded(
                            flex:6,
                            child: Container(
                              child: scanning==false?ClipRRect(

                                borderRadius:
                                BorderRadius.circular(16.0),
                                child:

                                ///***If you have exported images you must have to copy those images in assets/images directory.
                                Image(
                                  image: NetworkImage(
                                      "https://upload.wikimedia.org/wikipedia/commons/a/ac/Touch_%27n_Go_%282%29.png"),
                                  height: MediaQuery.of(context).size.height/2,
                                  width: MediaQuery.of(context).size.width/2,
                                ),
                              ):Container(
                                child: _buildQrView(context) ,
                              ),

                            )
                        ),
                        Expanded(
                            flex:1,
                            child: Container(
                              alignment: Alignment.center,
                              child: Text('RM50.00',style: TextStyle(fontSize: 40,fontWeight: FontWeight.bold),),
                            )
                        ),
                        Expanded(
                            flex:2,
                            child: Container(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: double.maxFinite,
                                height: 60,
                                child: ElevatedButton(

                                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blueAccent) ),
                                    onPressed: () async {
                                      await controller?.scannedDataStream;
                                        setState(() {
                                          scanning= true;

                                        });

                                      // await controller?.resumeCamera();
                                      // scanning= true;
                                      //

                                      // await controller?.resumeCamera();

                                    }, child: Text(scanning==false?"Start Scan":"Scanning...",style:TextStyle(fontSize: 25)),

                                ),
                              ),
                            )
                        ),
                        Expanded(flex: 1,child: Container(),)
                      ],
                    ) ,
                ):Container(),
              ),
            ],

          ),
        ),

    );


  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }



// function to calculate the input operation
//    equalPressed() {
//     String finaluserinput = userInput;
//     finaluserinput = userInput.replaceAll('x', '*');
//
//     Parser p = Parser();
//     Expression exp = p.parse(finaluserinput);
//     ContextModel cm = ContextModel();
//     double eval = exp.evaluate(EvaluationType.REAL, cm);
//     answer = eval.toString();
//   }

}
