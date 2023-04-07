import 'package:flutter/material.dart';
import 'package:pos_system/fragment/report/report_page.dart';
import 'package:pos_system/notifier/report_notifier.dart';
import 'package:provider/provider.dart';

class InitReportPage extends StatefulWidget {
  const InitReportPage({Key? key}) : super(key: key);

  @override
  State<InitReportPage> createState() => _InitReportPageState();
}

class _InitReportPageState extends State<InitReportPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportModel>(builder: (context, ReportModel reportModel, child) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
                flex: 12,
                child: ReportPage(report: reportModel))
          ],
        ),
      );
    });
  }
}
