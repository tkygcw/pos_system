import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lan_scanner/lan_scanner.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<HostModel> _hosts = <HostModel>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('lan_scanner example'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  final scanner = LanScanner(debugLogging: true);

                  final stream = scanner.icmpScan(
                    '192.168.0',
                    progressCallback: (progress) {
                      if (kDebugMode) {
                        print('progress: $progress');
                      }
                    },
                  );

                  stream.listen((HostModel host) {
                    setState(() {
                      _hosts.add(host);
                    });
                  });
                },
                child: const Text('Scan'),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final host = _hosts[index];

                  return Card(
                    child: ListTile(
                      title: Text(host.ip),
                    ),
                  );
                },
                itemCount: _hosts.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}