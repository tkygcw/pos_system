import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:presentation_displays/secondary_display.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../object/second_display_data.dart';

// Route<dynamic> generateRoute(RouteSettings settings) {
//   return MaterialPageRoute(
//       builder: (_) => Scaffold(
//         body: Center(
//             child: Text('No route defined for ${settings.name}')),
//       ));
//   // switch (settings.name) {
//   //   case '/display':
//   //     return MaterialPageRoute(builder: (_) => const DisplayManagerScreen());
//   //   case 'presentation':
//   //     return MaterialPageRoute(builder: (_) => const SecondaryScreen());
//   //   default:
//   //     return MaterialPageRoute(
//   //         builder: (_) => Scaffold(
//   //           body: Center(
//   //               child: Text('No route defined for ${settings.name}')),
//   //         ));
//   // }
// }


// class SecondDisplayTest  extends StatelessWidget {
//   const SecondDisplayTest ({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       onGenerateRoute: generateRoute,
//       initialRoute: '/display',
//     );
//   }
// }

class Button extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const Button({Key? key, required this.title, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 25),
        ),
      ),
    );
  }
}

/// Main Screen
class DisplayManagerScreen extends StatefulWidget {
  const DisplayManagerScreen({Key? key}) : super(key: key);

  @override
  _DisplayManagerScreenState createState() => _DisplayManagerScreenState();
}

class _DisplayManagerScreenState extends State<DisplayManagerScreen> {
  DisplayManager displayManager = DisplayManager();
  List<Display?> displays = [];

  final TextEditingController _indexToShareController = TextEditingController();
  final TextEditingController _dataToTransferController = TextEditingController();

  final TextEditingController _nameOfIdController = TextEditingController();
  String _nameOfId = "";
  final TextEditingController _nameOfIndexController = TextEditingController();
  String _nameOfIndex = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _getDisplays(),
              resetScreen(),
              _showPresentation(),
              _transferData(),
              _getDisplayeById(),
              _getDisplayByIndex(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getDisplays() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Button(
            title: "Get Displays",
            onPressed: () async {
              final values = await displayManager.getDisplays();
              displays.clear();
              setState(() {
                displays.addAll(values!);
              });
            }),
        ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: displays.length,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 50,
                child: Center(
                    child: Text('${displays[index]?.displayId} ${displays[index]?.name}')),
              );
            }),
        const Divider()
      ],
    );
  }

  Widget resetScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Button(
            title: "Reset Screen",
            onPressed: () async {
              String data = "init";
              await displayManager.transferDataToPresentation(data);
            }),
        const Divider()
      ],
    );
  }

  Widget _showPresentation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _indexToShareController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Index to share screen',
            ),
          ),
        ),
        Button(
            title: "Show presentation",
            onPressed: () async  {
              int? displayId = int.tryParse(_indexToShareController.text);
              if (displayId != null) {
                for (final display in displays) {
                  if (display?.displayId == displayId) {
                    await displayManager.showSecondaryDisplay(displayId: displayId, routerName: "presentation");
                  }
                }
              }
            }),
        const Divider(),
      ],
    );
  }

  Widget _transferData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _dataToTransferController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Data to transfer',
            ),
          ),
        ),
        Button(
            title: "TransferData",
            onPressed: () async {
              String data = _dataToTransferController.text;
              await displayManager.transferDataToPresentation(data);
            }),
        const Divider(),
      ],
    );
  }

  Widget _getDisplayeById() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _nameOfIdController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Id',
            ),
          ),
        ),
        Button(
            title: "NameByDisplayId",
            onPressed: () async {
              int? id = int.tryParse(_nameOfIdController.text);
              if (id != null) {
                final value = await displayManager
                    .getNameByDisplayId(displays[id]?.displayId ?? -1);
                setState(() {
                  _nameOfId = value ?? "";
                });
              }
            }),
        SizedBox(
          height: 50,
          child: Center(child: Text(_nameOfId)),
        ),
        const Divider(),
      ],
    );
  }

  Widget _getDisplayByIndex() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _nameOfIndexController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Index',
            ),
          ),
        ),
        Button(
            title: "NameByIndex",
            onPressed: () async {
              int? index = int.tryParse(_nameOfIndexController.text);
              if (index != null) {
                final value = await displayManager.getNameByIndex(index);
                setState(() {
                  _nameOfIndex = value ?? "";
                });
              }
            }),
        SizedBox(
          height: 50,
          child: Center(child: Text(_nameOfIndex)),
        ),
        const Divider(),
      ],
    );
  }
}

/// UI of Presentation display
class SecondaryScreen extends StatefulWidget {
  const SecondaryScreen({Key? key}) : super(key: key);

  @override
  _SecondaryScreenState createState() => _SecondaryScreenState();
}

class _SecondaryScreenState extends State<SecondaryScreen> {
  String value = "init";
  SecondDisplayData? obj;
  @override
  Widget build(BuildContext context) {
    return Consumer<CartModel>(builder: (context, CartModel cart, child) {
      return Scaffold(
          body: SecondaryDisplay(
              callback: (argument) {
                setState(() {
                  value = argument;
                  //var decode = SecondDisplayData.fromJson(argument);
                  if(argument != 'init'){
                    var decode = jsonDecode(argument);
                    obj = SecondDisplayData.fromJson(decode);
                    print('argument: ${decode}');
                  }
                });
              },
              child: value == "init"
                  ?
              Container(
                color: Colors.white24,
                child: Center(
                    child: Column(
                      children: [
                        Image.asset("drawable/logo.png"),
                      ],
                    )
                ),
              )
                  :
              Container(
                color: Colors.white24,
                child: Center(
                    child: Text('This is payment screen: cart notifier item: ${obj?.tableNo}\n'
                        'Item: ${obj?.itemList?[0].product_name}', style: TextStyle(fontSize: 35),)
                ),
              )
          ));
    });
  }
}
